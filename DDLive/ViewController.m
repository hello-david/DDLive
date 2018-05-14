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
#import "DDLiveAACEncoder.h"
#import "DDLiveAACDecoder.h"
#import "DDLivePCMPlayer.h"
#import "DDLiveFlvTag.h"

@interface ViewController () <DDLiveAVCaptureDelegate, DDLiveH264EncoderDelegate, DDLiveH264DecoderDelegate>
@property (nonatomic, strong) UIImageView *cameraImageView;
@property (nonatomic, strong) DDLiveAVCapture *capture;
@property (nonatomic, strong) DDLiveH264Encoder *h264Encoder;
@property (nonatomic, strong) DDLiveH264Decoder *h264Decoder;
@property (nonatomic, strong) DDLiveAACEncoder *aacEncoder;
@property (nonatomic, strong) DDLiveAACDecoder *aacDecoder;
@property (nonatomic, strong) DDLivePCMPlayer  *pcmPlayer;
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
    [self.h264Encoder encodeH264WithSampleBuffer:sampleBuffer];
}

- (void)didGetAudioBuffer:(CMSampleBufferRef)sampleBuffer {
    __weak typeof(self) weakSelf = self;
    [self.aacEncoder encodeSampleBuffer:sampleBuffer completionBlock:^(NSData *encodedData, NSError *error) {
        [weakSelf.aacDecoder decodeAACBuffer:encodedData completionBlock:^(NSData *pcmData, NSError *error) {
        
        }];
    }];
}

- (void)didH264Compress:(NSData *)data {
    [self.h264Decoder decodeH264WithNaluStream:data];
}

- (void)didH264CompressError:(NSError *)error {
    
}

- (void)didH264Decompress:(UIImage *)image {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.cameraImageView setImage:image];
    });
}

- (void)didH264DecompressError:(NSError *)error {
    
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

- (DDLiveH264Encoder *)h264Encoder {
    if(!_h264Encoder) {
        _h264Encoder = [[DDLiveH264Encoder alloc]initWithDelegate:self];
        [_h264Encoder configSessionWithWidth:640 height:480];
    }
    return _h264Encoder;
}

- (DDLiveH264Decoder *)h264Decoder {
    if(!_h264Decoder) {
        _h264Decoder = [[DDLiveH264Decoder alloc]initWithDelegate:self];
    }
    return _h264Decoder;
}

- (DDLiveAACEncoder *)aacEncoder {
    if(!_aacEncoder) {
        _aacEncoder = [[DDLiveAACEncoder alloc]init];
    }
    return _aacEncoder;
}

- (DDLiveAACDecoder *)aacDecoder {
    if(!_aacDecoder) {
        _aacDecoder = [[DDLiveAACDecoder alloc]init];
    }
    return _aacDecoder;
}

- (DDLivePCMPlayer *)pcmPlayer {
    if(!_pcmPlayer) {
        _pcmPlayer = [[DDLivePCMPlayer alloc]init];
    }
    return _pcmPlayer;
}
@end
