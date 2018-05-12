//
//  DDLiveH264Codec.h
//  DDLive
//
//  Created by Ming on 2018/5/11.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM(NSInteger,DDLiveH264FrameType)
{
    kH264FrameTypeNonIFrame    =   1,
    kH264FrameTypeIFrame       =   5,
    kH264FrameTypeSPS          =   7,
    kH264FrameTypePPS          =   8
};
