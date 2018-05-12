//
//  DDLiveAVCapture.m
//  DDLive
//
//  Created by Ming on 2018/5/11.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import "DDLiveAVCapture.h"
@interface DDLiveAVCapture() <
AVCaptureAudioDataOutputSampleBufferDelegate,
AVCaptureAudioDataOutputSampleBufferDelegate,
AVCaptureVideoDataOutputSampleBufferDelegate
>

@property (nonatomic, strong) AVCaptureDevice *inputCamera;
@property (nonatomic, strong) AVCaptureDevice *inputMicphone;
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong) AVCaptureDeviceInput *audioInput;
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioDataOutput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic, strong) AVCaptureSessionPreset capturePresent;

@end

@implementation DDLiveAVCapture

- (instancetype)initWithDelegate:(id<DDLiveAVCaptureDelegate>)delegate {
    if((self = [super init])) {
        self.delegate = delegate;
    }
    return self;
}

- (void)setupCaptureSession {
    dispatch_queue_t videoCaptureQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_queue_t audioCaptureQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    
    _captureSession = [[AVCaptureSession alloc]init];
    if([_captureSession canSetSessionPreset:AVCaptureSessionPreset640x480]){
        [_captureSession setSessionPreset:AVCaptureSessionPreset640x480];
        _capturePresent = AVCaptureSessionPreset640x480;
    }
    
    [_captureSession beginConfiguration];
    
    //get an AVCaptureDevice instance
    _inputCamera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    NSError *error = nil;
    //initialize an AVCaptureDeviceInput with camera (AVCaptureDevice)
    _videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:_inputCamera error:&error];
    if(error){
        NSLog(@"Camera error");
        return;
    }
    
    //add video input to AVCaptureSession
    if([self.captureSession canAddInput:_videoInput]) {
        [self.captureSession addInput:_videoInput];
    }
    
    //initialize an AVCaptureVideoDataOuput instance
    _videoDataOutput = [[AVCaptureVideoDataOutput alloc]init];
    [self.videoDataOutput setAlwaysDiscardsLateVideoFrames:NO];
    [self.videoDataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    [self.videoDataOutput setSampleBufferDelegate:self queue:videoCaptureQueue];
    
    //add video data output to capture session
    if([self.captureSession canAddOutput:self.videoDataOutput]){
        [self.captureSession addOutput:self.videoDataOutput];
    }
    
    //setting orientaion
    AVCaptureConnection *connection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    if ([connection isVideoStabilizationSupported]) {
        connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
    }
    connection.videoScaleAndCropFactor = connection.videoMaxScaleAndCropFactor;
    
    error = nil;
    //get an AVCaptureDevice for audio, here we want micphone
    _inputMicphone = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    //intialize the AVCaputreDeviceInput instance with micphone device
    _audioInput = [[AVCaptureDeviceInput alloc]initWithDevice:_inputMicphone error:&error];
    if(error){
        NSLog(@"micphone error");
    }
    
    //add audio device input to capture session
    if([self.captureSession canAddInput:_audioInput]){
        [self.captureSession addInput:_audioInput];
    }
    
    //initliaze an AVCaptureAudioDataOutput instance and set to
    self.audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
    if([self.captureSession canAddOutput:self.audioDataOutput]){
        [self.captureSession addOutput:self.audioDataOutput];
    }
    
    [self.audioDataOutput setSampleBufferDelegate:self queue:audioCaptureQueue];
    [self.captureSession commitConfiguration];
}

- (void)start {
    [self.captureSession startRunning];
}

- (void)stop {
    [self.captureSession stopRunning];
}

- (void)captureOutput:(AVCaptureOutput *)output
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    if(output == self.videoDataOutput) {
        if(self.delegate && [self.delegate respondsToSelector:@selector(didGetVideoBuffer:)]){
            [self.delegate didGetVideoBuffer:sampleBuffer];
        }
    }else if(output == self.audioDataOutput) {
        if(self.delegate &&[self.delegate respondsToSelector:@selector(didGetAudioBuffer:)]){
            [self.delegate didGetAudioBuffer:sampleBuffer];
        }
    }
}
@end
