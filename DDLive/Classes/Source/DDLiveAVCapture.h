//
//  DDLiveAVCapture.h
//  DDLive
//
//  Created by Ming on 2018/5/11.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol DDLiveAVCaptureDelegate <NSObject>
- (void)didGetVideoBuffer:(CMSampleBufferRef)sampleBuffer;
- (void)didGetAudioBuffer:(CMSampleBufferRef)sampleBuffer;
@end

@interface DDLiveAVCapture : NSObject
@property (nonatomic, weak) id<DDLiveAVCaptureDelegate> delegate;
@property (nonatomic, strong) AVCaptureSession *captureSession;

- (instancetype)initWithDelegate:(id <DDLiveAVCaptureDelegate>)delegate;
- (void)setupCaptureSession;
- (void)start;
- (void)stop;

@end
