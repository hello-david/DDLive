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
@property (nonatomic, assign) NSTimeInterval timestmap;
@property (nonatomic, strong) NSData *tag;
@property (nonatomic, strong) NSData *header;
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
            self.tag     = tag;
            self.header  = [tag subdataWithRange:NSMakeRange(0, kFlvTagHeaderLength)];
            self.tagData = [tag subdataWithRange:NSMakeRange(kFlvTagHeaderLength, tag.length - kFlvTagHeaderLength)];
            
            DDLiveFlvTagHeader tagHeader;
            [tag getBytes:&tagHeader length:sizeof(tagHeader)];
            self.timestmap = [DDLiveFlvTag timestmapWithUInt24:tagHeader.timestmap ex:tagHeader.timestmap_ex];
            self.tagType = tagHeader.type;
        }
    }
    return self;
}

- (instancetype)initWithTimestmap:(NSTimeInterval)timestmap tagData:(DDLiveFlvTagData *)tagData {
    if(self = [super init]){
        self.tagData   = [tagData data];
        self.timestmap = timestmap;
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
    [self setUInt24:tagHeader.dataSize hex:(UInt32)self.tagData.length];
    [self setUInt24:tagHeader.timestmap hex:(UInt32)self.timestmap];
    tagHeader.timestmap_ex = ((UInt32)self.timestmap) >> 24;
    [self setUInt24:tagHeader.streamID hex:0];
    
    self.header = [NSData dataWithBytes:&tagHeader length:sizeof(tagHeader)];
    NSMutableData *fullData = [NSMutableData dataWithData:self.header];
    [fullData appendData:self.tagData];
    self.tag = fullData;
}

- (void)setUInt24:(UInt24)array hex:(UInt32)hex {
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
