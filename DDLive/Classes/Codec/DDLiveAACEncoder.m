//
//  DDLiveAACEncoder.m
//  DDLive
//
//  Created by Ming on 2018/5/11.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import "DDLiveAACEncoder.h"
@interface DDLiveAACEncoder()
@property (nonatomic, assign) AudioConverterRef audioConverter;
@property (nonatomic, assign) uint8_t *aacBuffer;
@property (nonatomic, assign) NSUInteger aacBufferSize;
@property (nonatomic, assign) char *pcmBuffer;
@property (nonatomic, assign) size_t pcmBufferSize;
@property (nonatomic, strong) dispatch_queue_t encoderQueue;
@property (nonatomic, strong) dispatch_queue_t callbackQueue;
@end

@implementation DDLiveAACEncoder

- (void) dealloc {
    AudioConverterDispose(_audioConverter);
    free(_aacBuffer);
}

- (instancetype)init {
    if (self = [super init]) {
        _encoderQueue   = dispatch_queue_create("AAC Encoder Queue", DISPATCH_QUEUE_SERIAL);
        _callbackQueue  = dispatch_queue_create("AAC Encoder Callback Queue", DISPATCH_QUEUE_SERIAL);
        _audioConverter = NULL;
        _pcmBufferSize  = 0;
        _pcmBuffer      = NULL;
        _aacBufferSize  = 1024;
        _aacBuffer      = malloc(_aacBufferSize * sizeof(uint8_t));
        memset(_aacBuffer, 0, _aacBufferSize);
    }
    return self;
}

/**
 *  设置编码参数
 *  @param sampleBuffer 音频
 */
- (void)setupEncoderFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    AudioStreamBasicDescription inputFormat = *CMAudioFormatDescriptionGetStreamBasicDescription((CMAudioFormatDescriptionRef)CMSampleBufferGetFormatDescription(sampleBuffer));
    
    AudioStreamBasicDescription outputFormat = {0}; // 初始化输出流的结构体描述为0. 很重要。
    outputFormat.mSampleRate        = inputFormat.mSampleRate; // 音频流，在正常播放情况下的帧率。如果是压缩的格式，这个属性表示解压缩后的帧率。帧率不能为0。
    outputFormat.mFormatID          = kAudioFormatMPEG4AAC; // 设置编码格式
    outputFormat.mFormatFlags       = kMPEG4Object_AAC_LC; // 无损编码 ，0表示没有
    outputFormat.mBytesPerPacket    = 0; // 每一个packet的音频数据大小。如果的动态大小，设置为0。
    outputFormat.mFramesPerPacket   = 1024; // 每个packet的帧数。如果是未压缩的音频数据，值是1。动态码率格式，这个值是一个较大的固定数字，比如说AAC的1024。如果是动态大小帧数（比如Ogg格式）设置为0。
    outputFormat.mBytesPerFrame     = 0; // 每帧的大小。每一帧的起始点到下一帧的起始点。如果是压缩格式，设置为0。
    outputFormat.mChannelsPerFrame  = 1; // 声道数
    outputFormat.mBitsPerChannel    = 0; // 压缩格式设置为0
    outputFormat.mReserved          = 0; // 8字节对齐，填0.
    AudioClassDescription *description = [self getAudioClassDescriptionWithType:kAudioFormatMPEG4AAC
                                                               fromManufacturer:kAppleHardwareAudioCodecManufacturer];
    
    OSStatus status = AudioConverterNewSpecific(&inputFormat,
                                                &outputFormat,
                                                1,
                                                description,
                                                &_audioConverter); // 创建转换器
    if (status != noErr) {
        NSLog(@"setup converter fail: %d", (int)status);
    }
}

/**
 *  获取编解码器
 *
 *  @param type         编码格式
 *  @param manufacturer 软/硬编
 *
 *  @return 指定编码器
 */
- (AudioClassDescription *)getAudioClassDescriptionWithType:(UInt32)type
                                           fromManufacturer:(UInt32)manufacturer
{
    static AudioClassDescription desc;
    
    UInt32 encoderSpecifier = type;
    OSStatus st;
    
    UInt32 size;
    st = AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders,
                                    sizeof(encoderSpecifier),
                                    &encoderSpecifier,
                                    &size);
    if (st) {
        NSLog(@"error getting audio format propery info: %d", (int)(st));
        return nil;
    }
    
    unsigned int count = size / sizeof(AudioClassDescription);
    AudioClassDescription descriptions[count];
    st = AudioFormatGetProperty(kAudioFormatProperty_Encoders,
                                sizeof(encoderSpecifier),
                                &encoderSpecifier,
                                &size,
                                descriptions);
    if (st) {
        NSLog(@"error getting audio format propery: %d", (int)(st));
        return nil;
    }
    
    for (unsigned int i = 0; i < count; i++) {
        if ((type == descriptions[i].mSubType) &&
            (manufacturer == descriptions[i].mManufacturer)) {
            memcpy(&desc, &(descriptions[i]), sizeof(desc));
            return &desc;
        }
    }
    
    return nil;
}

/**
 *  填充到AAC编码会话
 */
OSStatus encoderInInputDataProc(AudioConverterRef inAudioConverter,
                                UInt32 *ioNumberDataPackets,
                                AudioBufferList *ioData,
                                AudioStreamPacketDescription **outDataPacketDescription,
                                void *inUserData)
{
    DDLiveAACEncoder *encoder = (__bridge DDLiveAACEncoder *)(inUserData);
    UInt32 requestedPackets = *ioNumberDataPackets;
    
    size_t copiedSamples = [encoder copyPCMSamplesIntoBuffer:ioData];
    if (copiedSamples < requestedPackets) {
        //PCM 缓冲区还没满
        *ioNumberDataPackets = 0;
        return -1;
    }
    *ioNumberDataPackets = 1;
    
    return noErr;
}

/**
 *  填充PCM到缓冲区
 */
- (size_t)copyPCMSamplesIntoBuffer:(AudioBufferList*)ioData {
    size_t originalBufferSize = _pcmBufferSize;
    if (!originalBufferSize) {
        return 0;
    }
    ioData->mBuffers[0].mData = _pcmBuffer;
    ioData->mBuffers[0].mDataByteSize = (int)_pcmBufferSize;
    _pcmBuffer = NULL;
    _pcmBufferSize = 0;
    return originalBufferSize;
}

- (void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer
           completionBlock:(void (^)(NSData * encodedData, NSError* error))completionBlock {
    
    CFRetain(sampleBuffer);
    dispatch_async(_encoderQueue, ^{
        if (!_audioConverter) {
            [self setupEncoderFromSampleBuffer:sampleBuffer];
        }
        CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
        CFRetain(blockBuffer);
        OSStatus status = CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &_pcmBufferSize, &_pcmBuffer);
        NSError *error = nil;
        if (status != kCMBlockBufferNoErr) {
            error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        }
        memset(_aacBuffer, 0, _aacBufferSize);
        
        AudioBufferList outAudioBufferList = {0};
        outAudioBufferList.mNumberBuffers = 1;
        outAudioBufferList.mBuffers[0].mNumberChannels = 1;
        outAudioBufferList.mBuffers[0].mDataByteSize = (int)_aacBufferSize;
        outAudioBufferList.mBuffers[0].mData = _aacBuffer;
        AudioStreamPacketDescription *outPacketDescription = NULL;
        UInt32 ioOutputDataPacketSize = 1;
        
        // 编码
        status = AudioConverterFillComplexBuffer(_audioConverter,
                                                 encoderInInputDataProc,
                                                 (__bridge void *)(self),
                                                 &ioOutputDataPacketSize,
                                                 &outAudioBufferList,
                                                 outPacketDescription);
        NSData *data = nil;
        if (status == 0) {
            NSData *rawAAC = [NSData dataWithBytes:outAudioBufferList.mBuffers[0].mData length:outAudioBufferList.mBuffers[0].mDataByteSize];
            NSData *adtsHeader = [DDLiveCodecTools adtsDataForPacketLength:rawAAC.length];
            NSMutableData *fullData = [NSMutableData dataWithData:adtsHeader];
            [fullData appendData:rawAAC];
            data = fullData;
        } else {
            error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        }
        if (completionBlock) {
            dispatch_async(_callbackQueue, ^{
                completionBlock(data, error);
            });
        }
        
        CFRelease(sampleBuffer);
        CFRelease(blockBuffer);
    });
}

@end
