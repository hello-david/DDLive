//
//  DDLiveFlvTag.h
//  DDLive
//
//  Created by David on 2018/5/14.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DDLiveFlvAudioTagData.h"
#import "DDLiveFlvVideoTagData.h"
#import "DDLiveFlvScriptTagData.h"

#define kFlvTagHeaderLength         11
#define kFlvHeaderLength            9
#define kFlvPreviosTagSizeLength    4

typedef NS_ENUM(NSInteger,FlvTagType) {
    kFlvTagTypeScript   = 0x12,
    kFlvTagTypeAudio    = 0x08,
    kFlvTagTypeVideo    = 0x09,
};

typedef UInt8 UInt24[3];

typedef struct __attribute__((packed)) {
    UInt24  signature;      // 文件标识，总为'FLV' 0x46 0x4c 0x66
    UInt8   version;        // 版本号0x01
    UInt8   flags;          // 前5位bit保留,第6位表示音频存在，第7位保留，第8位表示视频存在
    UInt32  headerSize;     // 版本1中总为9
} DDLiveFlvHeader;

typedef struct __attribute__((packed)) {
    UInt8   type;           // tag类型
    UInt24  dataSize;       // tagData部分的大小
    UInt24  timestmap;      // 播放时间戳低位，如数据为:0x6E 8D A8 01 即真实时间戳=0x01 6E 8D A8 = 24022440ms
    UInt8   timestmap_ex;   // 播放时间戳高位拓展
    UInt24  streamID;       // 总为0
} DDLiveFlvTagHeader;

@interface DDLiveFlvTag : NSObject

@property (nonatomic, readonly) NSData *tag;
@property (nonatomic, readonly) NSData *header;
@property (nonatomic, readonly) NSData *tagData;
@property (nonatomic, readonly) FlvTagType tagType;
@property (nonatomic, readonly) NSTimeInterval timestmap;// 毫秒级

+ (NSInteger)getTagDataSizeFromHeader:(NSData *)data;

- (instancetype)initWithTimestmap:(NSTimeInterval)timestmap tagData:(DDLiveFlvTagData *)tagData;
- (instancetype)initWithTag:(NSData *)tag;

@end
