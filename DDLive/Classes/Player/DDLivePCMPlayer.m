//
//  DDLivePCMPlayer.m
//  DDLive
//
//  Created by David on 2018/5/13.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import "DDLivePCMPlayer.h"

#define kOutputBus  0
#define kInputBus   1

@interface DDLivePCMPlayer()
@property (nonatomic, assign) AudioUnit audioUnit;
@property (nonatomic, strong) NSMutableData *audioBuffer;
@property (nonatomic, strong) dispatch_queue_t playerQueue;
@property (nonatomic, strong) NSLock *lock;
@end

@implementation DDLivePCMPlayer

- (instancetype)init {
    if(self = [super init]) {
        self.audioBuffer = [[NSMutableData alloc]init];
        _playerQueue  = dispatch_queue_create("PCM Player Queue", DISPATCH_QUEUE_SERIAL);
        _lock = [[NSLock alloc]init];
    }
    return self;
}

- (void)dealloc {
    [self stopPlayer];
}

- (void)startPlayer {
    // 播放会话
    NSError *error = nil;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    [audioSession setPreferredSampleRate:44100 error:&error];
    [audioSession setActive:YES error:&error];
    if(error) {
        NSLog(@"Audio Componet create fail :%@",error);
        return;
    }
    
    OSStatus status = noErr;
    AudioComponentDescription audioDesc;
    audioDesc.componentType     = kAudioUnitType_Output;
    audioDesc.componentSubType  = kAudioUnitSubType_VoiceProcessingIO;
    audioDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    audioDesc.componentFlags     = 0;
    audioDesc.componentFlagsMask = 0;
    
    // 创建组件
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &audioDesc);
    status = AudioComponentInstanceNew(inputComponent, &_audioUnit);
    if (status != noErr) {
        NSLog(@"Audio Componet create fail :%d",status);
        return;
    }
    
    // 输出格式
    AudioStreamBasicDescription outputFormat;
    memset(&outputFormat, 0, sizeof(outputFormat));
    outputFormat.mSampleRate       = 44100;
    outputFormat.mFormatID         = kAudioFormatLinearPCM;
    outputFormat.mFormatFlags      = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    outputFormat.mBytesPerPacket   = 2;
    outputFormat.mFramesPerPacket  = 1;
    outputFormat.mBytesPerFrame    = 2;
    outputFormat.mChannelsPerFrame = 1;
    outputFormat.mBitsPerChannel   = 16;
    outputFormat.mReserved         = 0;
    
    /**
     *  Audio Unit有两个设备Element,两个输入输出域，但
     *  输出设备Element 0的输出域(ouput scope)对你不可见，你只能写入它的输入域的数据及设置其输入域的音频格式
     *  输入设备Element 1的输入域(input scope)对你不可见，你只能读取它的输出域的数据及设置其输出域的音频格式
     */
    // 设置输出设备的输入域的流数据格式
    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  kOutputBus,
                                  &outputFormat,
                                  sizeof(outputFormat));
    if (status != noErr) {
        NSLog(@"AudioUnitSetProperty error with status:%d", status);
        return;
    }
    
    // 设置输出设备的输入域的回调
    AURenderCallbackStruct playCallback;
    playCallback.inputProc = PlayCallback;
    playCallback.inputProcRefCon = (__bridge void *)self;
    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Input,
                                  kOutputBus,
                                  &playCallback,
                                  sizeof(playCallback));
    if (status != noErr) {
        NSLog(@"AudioUnitSetProperty error with status:%d", status);
        return;
    }
    
    OSStatus result = AudioUnitInitialize(_audioUnit);
    if (result != noErr) {
        NSLog(@"AudioUnitInitialize eror with status:%d", status);
        return;
    }
    
    AudioOutputUnitStart(_audioUnit);
}

- (void)playPCM:(NSData *)pcmRawData {
    dispatch_async(_playerQueue, ^{
        if(!_audioUnit) {
            [self startPlayer];
        }
        [_lock lock];
        [_audioBuffer appendData:pcmRawData];
        [_lock unlock];
    });
}

- (NSData *)getPlayFrameWithSize:(uint32_t)size {
    
    if(!size) return nil;
    
    NSData *pcmData = nil;
    NSInteger pcmLength = size;
    [_lock lock];
    pcmData = [_audioBuffer subdataWithRange:NSMakeRange(0, pcmLength)];
    [_audioBuffer replaceBytesInRange:NSMakeRange(0, pcmLength) withBytes:NULL length:0];
    [_lock unlock];
    
    return pcmData;
}

-(void)stopPlayer {
    if(_audioUnit) {
        AudioOutputUnitStop(_audioUnit);
        AudioUnitUninitialize(_audioUnit);
        _audioUnit = NULL;
    }
}

#pragma mark - Audio Call Back
static OSStatus PlayCallback(void *inRefCon,
                             AudioUnitRenderActionFlags *ioActionFlags,
                             const AudioTimeStamp *inTimeStamp,
                             UInt32 inBusNumber,
                             UInt32 inNumberFrames,
                             AudioBufferList *ioData) {
    
    DDLivePCMPlayer *player = (__bridge DDLivePCMPlayer *)inRefCon;

    AudioBuffer buffer = ioData -> mBuffers[0];
    
    if (player.audioBuffer.length) {
        uint32_t size = (uint32_t)MIN(player.audioBuffer.length, buffer.mDataByteSize);
        NSData *pcmData = [player getPlayFrameWithSize:size];
        memcpy(buffer.mData, [pcmData bytes], size);
        buffer.mDataByteSize = size;
    }
    else{
        buffer.mDataByteSize = 0;
        *ioActionFlags |= kAudioUnitRenderAction_OutputIsSilence;
    }
    
    return noErr;
}
@end
