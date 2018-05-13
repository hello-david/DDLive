//
//  DDLivePCMPlayer.h
//  DDLive
//
//  Created by David on 2018/5/13.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AudioToolbox;
@import AVFoundation;

@interface DDLivePCMPlayer : NSObject

- (void)playPCM:(NSData *)pcmRawData;

@end
