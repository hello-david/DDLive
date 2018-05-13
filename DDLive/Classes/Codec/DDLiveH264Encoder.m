//
//  DDLiveH264Encoder.m
//  DDLive
//
//  Created by Ming on 2018/5/11.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import "DDLiveH264Encoder.h"

@interface DDLiveH264Encoder()
{
    VTCompressionSessionRef _encoderSession;
}
@property (nonatomic, assign) BOOL isInitialized;
@property (nonatomic, assign) NSInteger frameCount;
@property (nonatomic, assign) BOOL isGetMediaInfo;
@property (nonatomic, assign) int fps;
@property (nonatomic, strong) dispatch_queue_t encoderQueue;
@end

@implementation DDLiveH264Encoder

- (instancetype)initWithDelegate:(id<DDLiveH264EncoderDelegate>)delegate {
    if(self = [super init]) {
        self.delegate = delegate;
        _encoderQueue = dispatch_queue_create("com.ddlive.h264encoder", NULL);
    }
    return self;
}

- (void)configSessionWithWidth:(NSInteger)width height:(NSInteger)height {
    if(_encoderSession) {
        [self stopEncoder];
    }
    
    // 创建会话
    OSStatus status = VTCompressionSessionCreate(NULL,
                                                 (int)width,
                                                 (int)height,
                                                 kCMVideoCodecType_H264,NULL,NULL,NULL,
                                                 didCompress,
                                                 (__bridge void *)(self),
                                                 &_encoderSession);
    if (status != noErr)
    {
        NSLog(@"H264: VTCompressionSessionCreate fail %d", (int)status);
        if(self.delegate && [self respondsToSelector:@selector(didH264CompressError:)]) {
            [self.delegate didH264CompressError:[NSError errorWithDomain:@"Unable to create a H264 Encoder Session" code:status userInfo:nil]];
        }
        return ;
    }
    
    // 设置实时编码输出（避免延迟）
    VTSessionSetProperty(_encoderSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
    VTSessionSetProperty(_encoderSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Baseline_AutoLevel);
    
    // 设置关键帧间隔,每x帧输出1张关键帧(和帧率有关),由于动态帧率时间可能不固定
    int frameInterval = 60;
    CFNumberRef  frameIntervalRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &frameInterval);
    VTSessionSetProperty(_encoderSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, frameIntervalRef);
    
    // 设置关键帧间隔,每y秒输出1张关键帧,时间固定与前一个属性谁先达成谁生效
    int frameDuration = 2;
    CFNumberRef  frameDurationRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &frameDuration);
    VTSessionSetProperty(_encoderSession, kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration, frameDurationRef);
    
    // 设置期望帧率,每秒希望有多少帧数据
    _fps = 30;
    CFNumberRef  fpsRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &_fps);
    VTSessionSetProperty(_encoderSession, kVTCompressionPropertyKey_ExpectedFrameRate, fpsRef);
    
    // 设置码率均值,单位是bps
    int bitRate = (int)width * (int)height * 3 * 8;//平均1920*1080 3M/B
    CFNumberRef bitRateRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &bitRate);
    VTSessionSetProperty(_encoderSession, kVTCompressionPropertyKey_AverageBitRate, bitRateRef);
    
    // 设置码率上限,单位是byte
    int bitRateLimit = (int)width * (int)height * 10;//最高1920*1080 10M/B左右
    CFNumberRef bitRateLimitRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &bitRateLimit);
    VTSessionSetProperty(_encoderSession, kVTCompressionPropertyKey_DataRateLimits, bitRateLimitRef);
    
    // 准备编码
    VTCompressionSessionPrepareToEncodeFrames(_encoderSession);
    
    _isInitialized = YES;
}

- (void)encodeH264WithSampleBuffer:(CMSampleBufferRef)buffer {
    if(!_isInitialized || !buffer) return;
    CVImageBufferRef imageBuffer = (CVImageBufferRef)CMSampleBufferGetImageBuffer(buffer);
    [self encodeH264WithPixelBuffer:imageBuffer];
}

- (void)encodeH264WithPixelBuffer:(CVPixelBufferRef)buffer {
    if(!_isInitialized) return;
    CVPixelBufferRetain(buffer);
    dispatch_async(_encoderQueue, ^{
        CMTime presentationTimeStamp = CMTimeMake(_frameCount++, _fps);
        VTEncodeInfoFlags flags;
        OSStatus status = VTCompressionSessionEncodeFrame(_encoderSession,
                                                          buffer,
                                                          presentationTimeStamp,
                                                          kCMTimeInvalid,
                                                          NULL, NULL, &flags);
        if (status != noErr) {
            NSLog(@"H264: VTCompressionSessionEncodeFrame failed with %d", (int)status);
            if(self.delegate && [self respondsToSelector:@selector(didH264CompressError:)]) {
                [self.delegate didH264CompressError:[NSError errorWithDomain:@"VTCompressionSessionEncodeFrame failed" code:status userInfo:nil]];
            }
            [self stopEncoder];
            return;
        }
        CVPixelBufferRelease(buffer);
    });
}

- (void)stopEncoder {
    if(_encoderSession) {
        VTCompressionSessionCompleteFrames(_encoderSession, kCMTimeInvalid);
        VTCompressionSessionInvalidate(_encoderSession);
        CFRelease(_encoderSession);
        _encoderSession = NULL;
        _frameCount = 0;
        _isInitialized = NO;
        _isGetMediaInfo = NO;
    }
}

- (void)dealloc {
    [self stopEncoder];
}

#pragma mark - Compress Call back
void didCompress(void * CM_NULLABLE outputCallbackRefCon,
                 void * CM_NULLABLE sourceFrameRefCon,
                 OSStatus status,
                 VTEncodeInfoFlags infoFlags,
                 CM_NULLABLE CMSampleBufferRef sampleBuffer){
    if (status != 0) {
        return;
    }
    
    if (!CMSampleBufferDataIsReady(sampleBuffer)) {
        NSLog(@"didCompressH264 data is not ready ");
        return;
    }
    
    DDLiveH264Encoder* encoder = (__bridge DDLiveH264Encoder*)outputCallbackRefCon;
    bool keyframe = !CFDictionaryContainsKey((CFArrayGetValueAtIndex(CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true), 0)), kCMSampleAttachmentKey_NotSync);
    
    // 获取sps & pps数据
    if (keyframe && !encoder.isGetMediaInfo)
    {
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        size_t sparameterSetSize, sparameterSetCount;
        const uint8_t *sparameterSet;
        OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0,
                                                                                 &sparameterSet,
                                                                                 &sparameterSetSize,
                                                                                 &sparameterSetCount, 0 );
        if (statusCode == noErr)
        {
            size_t pparameterSetSize, pparameterSetCount;
            const uint8_t *pparameterSet;
            OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1,
                                                                                     &pparameterSet,
                                                                                     &pparameterSetSize,
                                                                                     &pparameterSetCount, 0 );
            if (statusCode == noErr)
            {
                NSData *sps = [NSData dataWithBytes:sparameterSet length:sparameterSetSize];
                NSData *pps = [NSData dataWithBytes:pparameterSet length:pparameterSetSize];
                if(encoder.delegate && [(id)encoder.delegate respondsToSelector:@selector(didH264Compress:)]){
                    [encoder.delegate didH264Compress:[encoder getStandardNalu:sps]];
                    [encoder.delegate didH264Compress:[encoder getStandardNalu:pps]];
                }
                encoder.isGetMediaInfo = YES;
            }
        }
    }
    
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t length, totalLength;
    char *dataPointer;
    OSStatus statusCodeRet = CMBlockBufferGetDataPointer(dataBuffer, 0, &length, &totalLength, &dataPointer);
    if (statusCodeRet == noErr) {
        size_t bufferOffset = 0;
        static const int AVCCHeaderLength = 4; // 返回的nalu数据前四个字节不是0001的startcode，而是大端模式的帧长度length
        // 循环获取nalu数据
        while (bufferOffset < totalLength - AVCCHeaderLength) {
            uint32_t NALUnitLength = 0;
            // 获取NALU数据长度
            memcpy(&NALUnitLength, dataPointer + bufferOffset, AVCCHeaderLength);
            
            // 从大端转系统端
            NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);
            NSData* naluData = [[NSData alloc] initWithBytes:(dataPointer + bufferOffset + AVCCHeaderLength) length:NALUnitLength];
            
            // 回调
            if(encoder.delegate && [(id)encoder.delegate respondsToSelector:@selector(didH264Compress:)]){
                [encoder.delegate didH264Compress:[encoder getStandardNalu:naluData]];
            }
            
            // 获取下一个NALU
            bufferOffset += AVCCHeaderLength + NALUnitLength;
        }
    }
}

- (NSData *)getStandardNalu:(NSData *)naluData
{
    // 添加NALU分割码
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1; // string literals have implicit trailing '\0'
    NSData *naluHeader = [NSData dataWithBytes:bytes length:length];
    NSMutableData *nalu = [[NSMutableData alloc]initWithData:naluHeader];
    [nalu appendData:naluData];
    return nalu;
}

@end
