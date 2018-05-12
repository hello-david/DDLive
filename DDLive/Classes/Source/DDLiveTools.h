//
//  DDLiveTools.h
//  DDLive
//
//  Created by David on 2018/5/12.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@import VideoToolbox;

#define CURRENT_SYSTEM_VERSION  ([[[UIDevice currentDevice] systemVersion] floatValue])

@interface DDLiveTools : NSObject

+ (UIImage *)pixelBufferToImage:(CVPixelBufferRef)pixelBuffer;

@end
