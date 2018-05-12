//
//  DDLiveH264Decoder.h
//  DDLive
//
//  Created by Ming on 2018/5/11.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DDLiveH264Codec.h"
#import "DDLiveTools.h"

@import VideoToolbox;
@import AVFoundation;

@protocol DDLiveH264DecoderDelegate <NSObject>
- (void)didDDLiveH264Decompress:(UIImage *)image;
- (void)didDDLiveH264DecompressError:(NSError *)error;
@end

@interface DDLiveH264Decoder : NSObject
@property (nonatomic, weak) id<DDLiveH264DecoderDelegate> delegate;

+ (DDLiveH264FrameType)getH264NaluType:(NSData *)nalu;
- (instancetype)initWithDelegate:(id<DDLiveH264DecoderDelegate>)delegate;
- (void)decodeH264WithNaluStream:(NSData *)nalus;
- (void)decodeH264WithAVAsset:(AVAsset *)asset;
- (void)stopDecoder;
@end
