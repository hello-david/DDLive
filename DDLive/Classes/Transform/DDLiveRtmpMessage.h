//
//  DDLiveRtmpMessage.h
//  DDLive
//
//  Created by David on 2018/5/19.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDLiveRtmpTypes.h"

@interface DDLiveRtmpMessage : NSObject

@property (nonatomic, strong) NSData *data;
@property (nonatomic, assign) RtmpMsgType type;
@property (nonatomic, assign) NSTimeInterval timestamp;

- (instancetype)initWithChunks:(NSArray *)chunks;

@end
