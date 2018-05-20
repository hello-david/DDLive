//
//  DDLiveFlvTag.h
//  DDLive
//
//  Created by David on 2018/5/14.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDLiveFlvTypes.h"
#import "DDLiveFlvAudioTagData.h"
#import "DDLiveFlvVideoTagData.h"
#import "DDLiveFlvScriptTagData.h"

@interface DDLiveFlvTag : NSObject

@property (nonatomic, readonly) NSData *data;
@property (nonatomic, readonly) NSData *tagHeader;
@property (nonatomic, readonly) NSData *tagData;
@property (nonatomic, readonly) FlvTagType tagType;
@property (nonatomic, readonly) NSTimeInterval timestamp;// 毫秒级

+ (NSInteger)getTagDataSizeFromHeader:(NSData *)data;
+ (void)setUInt24:(UInt24)array hex:(UInt32)hex;

- (instancetype)initWithTimestamp:(NSTimeInterval)timestamp tagData:(DDLiveFlvTagData *)tagData;
- (instancetype)initWithTag:(NSData *)tag;

@end
