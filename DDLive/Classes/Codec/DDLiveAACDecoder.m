//
//  DDLiveAACDecoder.m
//  DDLive
//
//  Created by Ming on 2018/5/11.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import "DDLiveAACDecoder.h"
@interface DDLiveAACDecoder()
@property (nonatomic, assign) AudioConverterRef audioConverter;
@property (nonatomic, strong) dispatch_queue_t decoderQueue;
@property (nonatomic, strong) dispatch_queue_t callbackQueue;
@end

@implementation DDLiveAACDecoder
- (void)dealloc {
    AudioConverterDispose(_audioConverter);
}

- (instancetype)init {
    if (self = [super init]) {
        _decoderQueue   = dispatch_queue_create("AAC decoder Queue", DISPATCH_QUEUE_SERIAL);
        _callbackQueue  = dispatch_queue_create("AAC decoder Callback Queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

/**
 *  设置解码参数
 */
- (void)setupAudioConverter{
    AudioStreamBasicDescription outFormat;
    memset(&outFormat, 0, sizeof(outFormat));
    outFormat.mSampleRate       = 44100;
    outFormat.mFormatID         = kAudioFormatLinearPCM;
    outFormat.mFormatFlags      = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    outFormat.mBytesPerPacket   = 2;
    outFormat.mFramesPerPacket  = 1;
    outFormat.mBytesPerFrame    = 2;
    outFormat.mChannelsPerFrame = 1;
    outFormat.mBitsPerChannel   = 16;
    outFormat.mReserved         = 0;
    
    AudioStreamBasicDescription inFormat;
    memset(&inFormat, 0, sizeof(inFormat));
    inFormat.mSampleRate        = 44100;
    inFormat.mFormatID          = kAudioFormatMPEG4AAC;
    inFormat.mFormatFlags       = kMPEG4Object_AAC_LC;
    inFormat.mBytesPerPacket    = 0;
    inFormat.mFramesPerPacket   = 1024;
    inFormat.mBytesPerFrame     = 0;
    inFormat.mChannelsPerFrame  = 1;
    inFormat.mBitsPerChannel    = 0;
    inFormat.mReserved          = 0;
    
    OSStatus status =  AudioConverterNew(&inFormat, &outFormat, &_audioConverter);
    if (status != noErr) {
        NSLog(@"setup converter fail: %d", (int)status);
    }
}

struct PassthroughUserData {
    UInt32 mChannels;
    UInt32 mDataSize;
    const void* mData;
    AudioStreamPacketDescription mPacket;
};
const uint32_t kNoMoreDataErr = 'MOAR';

OSStatus decoderInInputDataProc(AudioConverterRef aAudioConverter,
                                UInt32* aNumDataPackets /* in/out */,
                                AudioBufferList* aData /* in/out */,
                                AudioStreamPacketDescription** aPacketDesc,
                                void* aUserData)
{
    struct PassthroughUserData *userData = (struct PassthroughUserData*)aUserData;
    if (!userData->mDataSize) {
        *aNumDataPackets = 0;
        return kNoMoreDataErr;
    }

    if (aPacketDesc) {
        userData->mPacket.mStartOffset = 0;
        userData->mPacket.mVariableFramesInPacket = 0;
        userData->mPacket.mDataByteSize = userData->mDataSize;
        *aPacketDesc = &userData->mPacket;
    }

    aData->mBuffers[0].mNumberChannels = userData->mChannels;
    aData->mBuffers[0].mDataByteSize = userData->mDataSize;
    aData->mBuffers[0].mData = (void*)(userData->mData);

    // No more data to provide following this run.
    userData->mDataSize = 0;

    return noErr;
}

- (void)decodeAACBuffer:(NSData *)adtsAAC completionBlock:(void (^)(NSData *, NSError *))completionBlock {
    
    dispatch_async(_decoderQueue, ^{
        if(!_audioConverter){
            [self setupAudioConverter];
        }

        //去除atds头部
        NSData *aacData = [DDLiveCodecTools aacRawDataFromADTSAAC:adtsAAC];
        
        struct PassthroughUserData userData = { 1, (UInt32)aacData.length, [aacData bytes]};
        NSMutableData *decodedData = [[NSMutableData alloc]init];

        const uint32_t MAX_AUDIO_FRAMES = 128;
        const uint32_t maxDecodedSamples = MAX_AUDIO_FRAMES * 1;
        
        NSError *error = nil;
        do{
            uint8_t *buffer = (uint8_t *)malloc(maxDecodedSamples * sizeof(short int));
            AudioBufferList decBuffer;
            decBuffer.mNumberBuffers = 1;
            decBuffer.mBuffers[0].mNumberChannels = 1;
            decBuffer.mBuffers[0].mDataByteSize = maxDecodedSamples * sizeof(short int);
            decBuffer.mBuffers[0].mData = buffer;

            UInt32 numFrames = MAX_AUDIO_FRAMES;

            AudioStreamPacketDescription outPacketDescription;
            memset(&outPacketDescription, 0, sizeof(AudioStreamPacketDescription));
            outPacketDescription.mDataByteSize = MAX_AUDIO_FRAMES;
            outPacketDescription.mStartOffset = 0;
            outPacketDescription.mVariableFramesInPacket = 0;

            // 解码
            OSStatus status = AudioConverterFillComplexBuffer(_audioConverter,
                                                              decoderInInputDataProc,
                                                              &userData,
                                                              &numFrames /* in/out */,
                                                              &decBuffer,
                                                              &outPacketDescription);
            if (status && status != kNoMoreDataErr) {
                NSLog(@"Error decoding audio stream: %d\n", status);
                error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
                decodedData = nil;
                break;
            }

            if (numFrames) {
                [decodedData appendBytes:decBuffer.mBuffers[0].mData length:decBuffer.mBuffers[0].mDataByteSize];
            }

            if (status == kNoMoreDataErr) {
                break;
            }
        }while (true);
        
        dispatch_async(_callbackQueue, ^{
            completionBlock(decodedData, error);
        });
    });
}

@end
