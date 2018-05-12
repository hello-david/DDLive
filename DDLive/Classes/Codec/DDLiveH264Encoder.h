//
//  DDLiveH264Encoder.h
//  DDLive
//
//  Created by Ming on 2018/5/11.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDLiveTools.h"

@import VideoToolbox;
@import AVFoundation;

@protocol DDLiveH264EncoderDelegate
- (void)didDDLiveH264Compress:(NSData *)data;
- (void)didDDLiveH264CompressError:(NSError *)error;
@end

@interface DDLiveH264Encoder : NSObject
@property (nonatomic, weak) id<DDLiveH264EncoderDelegate> delegate;

- (instancetype)initWithDelegate:(id<DDLiveH264EncoderDelegate>)delegate;
- (void)configSessionWithWidth:(NSInteger)width height:(NSInteger)height;
- (void)encodeH264WithPixelBuffer:(CVPixelBufferRef)buffer;
- (void)encodeH264WithSampleBuffer:(CMSampleBufferRef)buffer;
- (void)stopEncoder;

@end
