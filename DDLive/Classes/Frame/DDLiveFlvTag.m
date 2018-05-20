//
//  DDLiveFlvTag.m
//  DDLive
//
//  Created by David on 2018/5/14.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import "DDLiveFlvTag.h"

@interface DDLiveFlvTag()
@property (nonatomic, assign) FlvTagType tagType;
@property (nonatomic, assign) NSTimeInterval timestamp;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSData *tagHeader;
@property (nonatomic, strong) NSData *tagData;
@end

@implementation DDLiveFlvTag

+ (NSInteger)getTagDataSizeFromHeader:(NSData *)data {
    NSInteger tagSize = 0;
    if(data.length >= kFlvTagHeaderLength) {
        DDLiveFlvTagHeader tagHeader;
        [data getBytes:&tagHeader length:sizeof(tagHeader)];
        tagSize = (NSInteger)[DDLiveFlvTag floatUInt24:tagHeader.dataSize];
    }
    return tagSize;
}

- (instancetype)initWithTag:(NSData *)tag {
    if(self = [super init]) {
        if(tag.length > kFlvTagHeaderLength) {
            self.data       = tag;
            self.tagHeader  = [tag subdataWithRange:NSMakeRange(0, kFlvTagHeaderLength)];
            self.tagData    = [tag subdataWithRange:NSMakeRange(kFlvTagHeaderLength, tag.length - kFlvTagHeaderLength)];
            
            DDLiveFlvTagHeader tagHeader;
            [tag getBytes:&tagHeader length:sizeof(tagHeader)];
            self.timestamp = [DDLiveFlvTag timestmapWithUInt24:tagHeader.timestamp ex:tagHeader.timestamp_ex];
            self.tagType = tagHeader.type;
        }
    }
    return self;
}

- (instancetype)initWithTimestamp:(NSTimeInterval)timestamp tagData:(DDLiveFlvTagData *)tagData {
    if(self = [super init]){
        self.tagData   = [tagData data];
        self.timestamp = timestamp;
        [self packgeFlvTag];
    }
    return self;
}

- (void)packgeFlvTag {
    if(!self.tagData) {
        return;
    }
    
    DDLiveFlvTagHeader tagHeader;
    tagHeader.type = (UInt8)self.tagType;
    [DDLiveFlvTag setUInt24:tagHeader.dataSize hex:(UInt32)self.tagData.length];
    [DDLiveFlvTag setUInt24:tagHeader.timestamp hex:(UInt32)self.timestamp];
    tagHeader.timestamp_ex = ((UInt32)self.timestamp) >> 24;
    [DDLiveFlvTag setUInt24:tagHeader.streamID hex:0];
    
    self.tagHeader = [NSData dataWithBytes:&tagHeader length:sizeof(tagHeader)];
    NSMutableData *fullData = [NSMutableData dataWithData:self.tagHeader];
    [fullData appendData:self.tagData];
    self.data = fullData;
}

+ (void)setUInt24:(UInt24)array hex:(UInt32)hex {
    if(hex >= (0x01 << 25)) {
        NSLog(@"DDLiveTag overflow");
    }
    
    UInt32 hex24 = hex << 8 >> 8;
    array[0] = hex24 >> 16 & 0xff;
    array[1] = hex24 >> 8 & 0x00ff;
    array[2] = hex24 & 0x0000ff;
}

+ (NSTimeInterval)timestmapWithUInt24:(UInt24)array ex:(UInt8)ex {
    return (NSTimeInterval)([self floatUInt24:array] + (ex << 24));
}

+ (float)floatUInt24:(UInt24)array {
    return (array[0] << 16) + (array[1] << 8) + (array[2]);
}

+ (NSString *)stringUInt24:(UInt24)array {
    return [NSString stringWithFormat:@"%02X%02X%02X", array[0], array[1], array[2]];
}

@end
