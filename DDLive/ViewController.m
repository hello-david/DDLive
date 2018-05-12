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
#import "DDLiveH264Encoder.h"
#import "DDLiveH264Decoder.h"

@interface ViewController () <DDLiveAVCaptureDelegate, DDLiveH264EncoderDelegate, DDLiveH264DecoderDelegate>
@property (nonatomic, strong) UIImageView *cameraImageView;
@property (nonatomic, strong) DDLiveAVCapture *capture;
@property (nonatomic, strong) DDLiveH264Encoder *encoder;
@property (nonatomic, strong) DDLiveH264Decoder *decoder;
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

#pragma mark - Delegate
- (void)didGetVideoBuffer:(CMSampleBufferRef)sampleBuffer {
    [self.encoder encodeH264WithSampleBuffer:sampleBuffer];
    
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    UIImage *image = [DDLiveTools pixelBufferToImage:pixelBuffer];

}

- (void)didGetAudioBuffer:(CMSampleBufferRef)sampleBuffer {
    
}

- (void)didDDLiveH264Compress:(NSData *)data {
    [self.decoder decodeH264WithNaluStream:data];
}

- (void)didDDLiveH264CompressError:(NSError *)error {
    
}

- (void)didDDLiveH264Decompress:(UIImage *)image {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.cameraImageView setImage:image];
    });
}

- (void)didDDLiveH264DecompressError:(NSError *)error {
    
}
#pragma mark - Property
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

- (DDLiveH264Encoder *)encoder {
    if(!_encoder) {
        _encoder = [[DDLiveH264Encoder alloc]initWithDelegate:self];
        [_encoder configSessionWithWidth:640 height:480];
    }
    return _encoder;
}

- (DDLiveH264Decoder *)decoder {
    if(!_decoder) {
        _decoder = [[DDLiveH264Decoder alloc]initWithDelegate:self];
    }
    return _decoder;
}
@end
