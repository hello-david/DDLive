//
//  DDLiveCodecTools.h
//  DDLive
//
//  Created by David on 2018/5/13.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AudioToolbox;
@import AVFoundation;

typedef NS_ENUM(NSInteger,DDLiveH264FrameType)
{
    kH264FrameTypeNonIFrame    =   1,
    kH264FrameTypeIFrame       =   5,
    kH264FrameTypeSPS          =   7,
    kH264FrameTypePPS          =   8
};

@interface DDLiveCodecTools : NSObject

+ (NSData *)adtsDataForPacketLength:(NSUInteger)packetLength;
+ (NSData *)aacRawDataFromADTSAAC:(NSData *)adtsAAC;

@end
