//
//  DDLiveH264Decoder.m
//  DDLive
//
//  Created by Ming on 2018/5/11.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import "DDLiveH264Decoder.h"

@interface DDLiveH264Decoder()
{
    VTDecompressionSessionRef _decoderSession;
    CMVideoFormatDescriptionRef _videoFormatDESC;
    dispatch_queue_t _decodeThread;
}
@property (nonatomic, strong) NSData *spsData;
@property (nonatomic, strong) NSData *ppsData;
@property (nonatomic, assign) BOOL isGetFirstIFrame;
@end

@implementation DDLiveH264Decoder

+ (DDLiveH264FrameType)getH264NaluType:(NSData *)nalu {
    NSInteger nalType;
    if(nalu.length < 4) return 0;
    [nalu getBytes:&nalType range:NSMakeRange(4, 1)];
    nalType = nalType & 0x1F;
    return nalType;
}

- (instancetype)initWithDelegate:(id<DDLiveH264DecoderDelegate>)delegate {
    if(self = [super init]){
        self.delegate = delegate;
        _decodeThread = dispatch_queue_create("com.ddlive.h264decoder", NULL);
    }
    return self;
}

- (void)decodeH264WithNaluStream:(NSData *)nalus {
    dispatch_async(_decodeThread, ^{
       [self decodeProcess:nalus];
    });
}

- (void)decodeH264WithAVAsset:(AVAsset *)asset {
    
}

- (void)stopDecoder {
    //clean session
    if (_decoderSession && (_decoderSession != NULL)) {
        VTDecompressionSessionInvalidate(_decoderSession);
        CFRelease(_decoderSession);
        _decoderSession = nil;
    }
    
    //clean config
    if(_videoFormatDESC != NULL) {
        CFRelease(_videoFormatDESC);
        _videoFormatDESC = NULL;
    }
    _spsData = nil;
    _ppsData = nil;
    _isGetFirstIFrame = NO;
}

- (void)dealloc {
    [self stopDecoder];
    self.delegate = nil;
}

#pragma mark - Decoder Session Init
- (OSStatus)h264DecoderSessionInit
{
    if(_decoderSession) return noErr;
    OSStatus status = noErr;
    
    //read NAL type from first Byte of NALU，here deliver data pointer
    const uint8_t* const paraSetPointers[2] = { [_spsData bytes], [_ppsData bytes] };
    const size_t paraSetSizes[2] = {_spsData.length, _ppsData.length };
    
    //src video fomat config
    if(!_spsData||!_ppsData)
    {
        NSLog(@"H264 Decoder Do not have sps or pps!");
        return status;
    }
    status = CMVideoFormatDescriptionCreateFromH264ParameterSets(NULL,
                                                                 2,                   //at least 2 types
                                                                 paraSetPointers,
                                                                 paraSetSizes,
                                                                 4,
                                                                 &_videoFormatDESC);
    if(status != noErr)
    {
        NSLog(@"H264 Decoder video format desc create err:%d",(int)status);
        return status;
    }
    
    //output frame format config
    CFDictionaryRef pixelBufferAttrs = nil;
    uint32_t videoFormat = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;//output frame format is NV12
    const void *values[] = { CFNumberCreate(NULL, kCFNumberSInt32Type, &videoFormat) };
    const void *keys[] = { kCVPixelBufferPixelFormatTypeKey };
    pixelBufferAttrs = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
    
    //when decoder in asynchronous mode ,setting effective
    VTDecompressionOutputCallbackRecord callBackRecord;
    callBackRecord.decompressionOutputCallback = didDecompress;
    callBackRecord.decompressionOutputRefCon   = (__bridge void * _Nullable)(self);
    
    //create session
    status = VTDecompressionSessionCreate(NULL,               //allocator create by defalut
                                          _videoFormatDESC,    //src video format desc
                                          NULL,               //decoder chose by defalut
                                          pixelBufferAttrs,   //pixel buffer format
                                          &callBackRecord,    //decode callback handle
                                          &_decoderSession);   //session handle
    CFRelease(pixelBufferAttrs);
    if(status != noErr) {
        NSLog(@"H264 Decoder session create err :%d",(int)status);
        return status;
    }
    else {
        NSLog(@"H264 Decoder session create");
        return noErr;
    }
}

#pragma mark - Decoder Process
- (void)decodeProcess:(NSData *)nalu
{
    if(!nalu.length)return;
    
    NSInteger naluType = [DDLiveH264Decoder getH264NaluType:nalu];
    switch (naluType) {
        case kH264FrameTypeSPS: {
            NSLog(@"H264 Decoder Get SPS NALU");
            _spsData = [[NSData alloc]initWithData:[nalu subdataWithRange:NSMakeRange(4, nalu.length - 4)]];
            return;
        }
        case kH264FrameTypePPS: {
            NSLog(@"H264 Decoder Get PPS NALU");
            _ppsData = [[NSData alloc]initWithData:[nalu subdataWithRange:NSMakeRange(4, nalu.length - 4)]];
            return;
        }
        case kH264FrameTypeNonIFrame: {
            if(!_isGetFirstIFrame)
            {
                NSLog(@"H264 Decoder Haven't Get I Frame Yet");
                return;
            }
            break;
        }
            
        case kH264FrameTypeIFrame: {
            NSLog(@"H264 Decoder Get I frame");
            (!_isGetFirstIFrame) ? (_isGetFirstIFrame = YES) : 0;
            break;
        }
            
        default: {
            return;
        }
    }
    
    //init decoder
    OSStatus initState = [self h264DecoderSessionInit];
    if(initState != noErr) {
        [self stopDecoder];
        if(self.delegate && [self.delegate respondsToSelector:@selector(didH264DecompressError:)]) {
            [self.delegate didH264DecompressError:[NSError errorWithDomain:@"H264 Init Session Error" code:initState userInfo:nil]];
        }
        return;
    }
    
    if(!_decoderSession) return;
    
    NSInteger streamLen = nalu.length;
    
    //change start code to NAL packet size order by big-endian
    //set nalu to mp4 format
    int tempLen = (int)streamLen-4;
    tempLen = CFSwapInt32HostToBig(tempLen);
    NSMutableData *temp = [[NSMutableData alloc] init];
    [temp appendData:nalu];
    [temp replaceBytesInRange:NSMakeRange(0, 4) withBytes:&tempLen length:4];
    
    //conver (NSData*)nalu to (void*)nalu
    void *data = malloc(streamLen);
    if (data == NULL) {
        NSLog(@"H264 Decoder buffer malloc mem err");
        return;
    }
    [temp getBytes:data range:NSMakeRange(0, streamLen)];
    
    //nalu block conver to CMBlockBuffer
    OSStatus status;
    CMBlockBufferRef blockBuffer = nil;//buffer handle
    status = CMBlockBufferCreateWithMemoryBlock(NULL,
                                                data,             //mem block pointer
                                                streamLen,        //mem block len
                                                NULL,
                                                NULL,
                                                0,                //copy index
                                                streamLen,        //len
                                                0,
                                                &blockBuffer);    //handle
    if(status != kCMBlockBufferNoErr) {
        NSLog(@"H264 Decoder nalu decode buffer create err");
        free(data);
        
        [self stopDecoder];
        if(self.delegate && [self.delegate respondsToSelector:@selector(didH264DecompressError:)]){
            [self.delegate didH264DecompressError:[NSError errorWithDomain:@"H264 Decoder nalu decode buffer create err" code:status userInfo:nil]];
        }
        return;
    }
    
    //create decoder CMSampleBuffer
    CMSampleBufferRef sampleBuffer = nil;
    const size_t sampleSizeArray[] = {streamLen};
    status = CMSampleBufferCreateReady(NULL,
                                       blockBuffer,
                                       _videoFormatDESC,
                                       1,                   //num of sample in buffer
                                       0,                   //num of entries in sampleTimingArray
                                       NULL,                //sampleTimingArray
                                       1,                   //num of entries in sampleSizeArray
                                       sampleSizeArray,
                                       &sampleBuffer);
    if (status != kCMBlockBufferNoErr || !sampleBuffer) {
        CFRelease(blockBuffer);
        
        [self stopDecoder];
        if(self.delegate && [self.delegate respondsToSelector:@selector(didH264DecompressError:)]){
            [self.delegate didH264DecompressError:[NSError errorWithDomain:@"H264 Decoder sample bufer create error" code:status userInfo:nil]];
        }
        return;
    }
    
    //put nalu into decoder,decode in synchronous mode(freameFlags=0)
    VTDecodeFrameFlags frameFlags = 0;//async flagss=kVTDecodeFrame_EnableAsynchronousDecompression
    VTDecodeInfoFlags  infoFlags  = 0;
    CVPixelBufferRef  outputPixelBuffer = nil;
    status = VTDecompressionSessionDecodeFrame(_decoderSession,
                                               sampleBuffer,
                                               frameFlags,
                                               &outputPixelBuffer,
                                               &infoFlags);
    CFRelease(sampleBuffer);
    CFRelease(blockBuffer);
    
    if(status != noErr) {
        NSLog(@"H264 Decoder: decode error status = %d", (int)status);
        [self stopDecoder];
        if(self.delegate && [self.delegate respondsToSelector:@selector(didH264DecompressError:)]){
            [self.delegate didH264DecompressError:[NSError errorWithDomain:@"H264 Decoders decode failed" code:status userInfo:nil]];
        }
    }
}

#pragma mark - Decoder Call Back
static void didDecompress(void *decompressionOutputRefCon,
                          void *sourceFrameRefCon,
                          OSStatus status,
                          VTDecodeInfoFlags infoFlags,
                          CVImageBufferRef pixelBuffer,
                          CMTime presentationTimeStamp,
                          CMTime presentationDuration ) {
    if(!pixelBuffer) return;
    UIImage *image = [DDLiveTools pixelBufferToImage:pixelBuffer];
    
    DDLiveH264Decoder *decoder = (__bridge DDLiveH264Decoder *)decompressionOutputRefCon;
    if(decoder.delegate && [decoder.delegate respondsToSelector:@selector(didH264Decompress:)]){
        [decoder.delegate didH264Decompress:image];
    }
}

@end
