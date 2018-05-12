//
//  ViewController.m
//  DDLive
//
//  Created by Ming on 2018/5/11.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import "ViewController.h"
#import <UIKit/UIKit.h>
#import "Masonry.h"
#import "DDLiveAVCapture.h"
#import "DDLiveTools.h"

@interface ViewController () <DDLiveAVCaptureDelegate>
@property (nonatomic, strong) UIImageView *cameraImageView;
@property (nonatomic, strong) DDLiveAVCapture *capture;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.cameraImageView];
    [self.cameraImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.view).offset(20);
        make.height.equalTo(@400);
    }];
    
    [self.capture setupCaptureSession];
    [self.capture start];
}

- (void)didGetVideoBuffer:(CMSampleBufferRef)sampleBuffer {
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    UIImage *image = [DDLiveTools pixelBufferToImage:pixelBuffer];
    dispatch_async(dispatch_get_main_queue(), ^{
       [self.cameraImageView setImage:image];
    });
}

- (void)didGetAudioBuffer:(CMSampleBufferRef)sampleBuffer {
    
}

- (UIImageView *)cameraImageView {
    if(!_cameraImageView) {
        _cameraImageView = [[UIImageView alloc]init];
    }
    return _cameraImageView;
}

- (DDLiveAVCapture *)capture {
    if(!_capture) {
        _capture = [[DDLiveAVCapture alloc]initWithDelegate:self];
    }
    return _capture;
}

@end
