//
//  DDLiveRtmpMessage.m
//  DDLive
//
//  Created by David on 2018/5/19.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import "DDLiveRtmpMessage.h"

@interface DDLiveRtmpMessage()

@property (nonatomic, assign) DDLiveRtmpChunkMessageHeader0 header0;
@property (nonatomic, assign) DDLiveRtmpChunkMessageHeader1 header1;
@property (nonatomic, assign) DDLiveRtmpChunkMessageHeader2 header2;
@property (nonatomic, strong) NSArray *chunks;

@end

@implementation DDLiveRtmpMessage

- (instancetype)initWithChunks:(NSArray *)chunks {
    if (self = [super init]) {
        self.chunks = chunks;
        self.type   = -1;
        [self decodeMessage];
    }
    return self;
}

- (void)decodeMessage {
    NSData *firstChunk = [self.chunks firstObject];
    NSData *firstMessageData = nil;
    NSMutableData *messageData = [[NSMutableData alloc]init];
    DDLiveRtmpChunkBasicHeader0 chunkHeader;
    [firstChunk getBytes:&chunkHeader length:sizeof(chunkHeader)];
    
    if(chunkHeader.chunkType == kRtmpChunkTypeFullMessage) {
        NSRange headerRange    = NSMakeRange(kRtmpChunkBasicHeader0Size, kRtmpChunkMessageHeader0Size);
        NSInteger headerLength = kRtmpChunkBasicHeader0Size + kRtmpChunkMessageHeader0Size;
        [firstChunk getBytes:&_header0 range:headerRange];
        
        // 时间戳溢出，多了一个ex时间戳字段
        _timestamp = _header0.timestamp.data;
        NSInteger exTimestampLength = 0;
        if(_timestamp == 0xffffff) {
            exTimestampLength = 4;
            NSData *timestampData = [firstChunk subdataWithRange:NSMakeRange(headerLength, exTimestampLength)];
            [timestampData getBytes:&_timestamp range:NSMakeRange(0, exTimestampLength)];
            headerLength += exTimestampLength;
        }
        
        NSRange dataRange = NSMakeRange(headerLength, firstChunk.length - headerLength);
        firstMessageData = [firstChunk subdataWithRange:dataRange];
        self.type        = _header0.messageType;
        
    }
    
    else if(chunkHeader.chunkType == kRtmpChunkTypeSameStreamMessage) {
        NSRange headerRange    = NSMakeRange(kRtmpChunkBasicHeader0Size, kRtmpChunkMessageHeader1Size);
        NSInteger headerLength = kRtmpChunkBasicHeader0Size + kRtmpChunkMessageHeader1Size;
        
        // 时间戳溢出，多了一个ex时间戳字段
        _timestamp = _header1.timestampDelta.data;
        NSInteger exTimestampLength = 0;
        if(_timestamp == 0xffffff) {
            exTimestampLength = 4;
            NSData *timestampData = [firstChunk subdataWithRange:NSMakeRange(headerLength, exTimestampLength)];
            [timestampData getBytes:&_timestamp range:NSMakeRange(0, exTimestampLength)];
            headerLength += exTimestampLength;
        }
        
        NSRange dataRange = NSMakeRange(headerLength, firstChunk.length - headerLength);
        [firstChunk getBytes:&_header1 range:headerRange];
        firstMessageData = [firstChunk subdataWithRange:dataRange];
        self.type = _header1.messageType;
    }
    
    else if(chunkHeader.chunkType == kRtmpChunkTypeSameSizeMessage) {
        NSRange headerRange    = NSMakeRange(kRtmpChunkBasicHeader0Size, kRtmpChunkMessageHeader2Size);
        NSInteger headerLength = kRtmpChunkBasicHeader0Size + kRtmpChunkMessageHeader2Size;
        
        // 时间戳溢出，多了一个ex时间戳字段
        _timestamp = _header2.timestampDelta.data;
        NSInteger exTimestampLength = 0;
        if(_timestamp == 0xffffff) {
            exTimestampLength = 4;
            NSData *timestampData = [firstChunk subdataWithRange:NSMakeRange(headerLength, exTimestampLength)];
            [timestampData getBytes:&_timestamp range:NSMakeRange(0, exTimestampLength)];
            headerLength += exTimestampLength;
        }
        
        NSRange dataRange = NSMakeRange(headerLength, firstChunk.length - headerLength);
        [firstChunk getBytes:&_header2  range:headerRange];
        firstMessageData = [firstChunk subdataWithRange:dataRange];
    }
    
    [messageData appendData:firstMessageData];
    for (int i = 1; i < self.chunks.count; i++) {
        NSData *childChunks = [self.chunks objectAtIndex:i];
        NSInteger headerLength = kRtmpChunkBasicHeader0Size;
        NSRange dataRange = NSMakeRange(headerLength, firstChunk.length - headerLength);
        NSData *data = [childChunks subdataWithRange:dataRange];
        
        [messageData appendData:data];
    }
    
    self.data = messageData;
}

@end
