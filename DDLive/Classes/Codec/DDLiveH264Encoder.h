//
//  DDLiveH264Encoder.h
//  DDLive
//
//  Created by Ming on 2018/5/11.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import <Foundation/Foundation.h>
@import VideoToolbox;
@import AVFoundation;

@protocol DDLiveH264EncoderDelegate
- (void)didDDLiveH264Encode:(NSData *)data;
- (void)didDDLiveH264EncodeError:(NSError *)error;
@end

@interface DDLiveH264Encoder : NSObject
@property (nonatomic, weak) id<DDLiveH264EncoderDelegate> delegate;

- (instancetype)initWithDelegate:(DDLiveH264Encoder *)delegate;
- (void)encodeH264WithPixelBuffer:(CVPixelBufferRef)buffer;
- (void)stopEncoder;

@end
