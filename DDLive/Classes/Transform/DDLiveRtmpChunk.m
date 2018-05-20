//
//  DDLiveRtmpChunk.m
//  DDLive
//
//  Created by David on 2018/5/19.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import "DDLiveRtmpChunk.h"

@interface DDLiveRtmpChunk()

@property (nonatomic, strong) NSMutableArray *tmpChunks;
@property (nonatomic, strong) NSMutableData  *tmpChunkPool;
@property (nonatomic, assign) NSInteger firstMsgLength;
@property (nonatomic, assign) NSInteger currentMsgLength;
@property (nonatomic, assign) NSInteger lastMsgLength;

@property (nonatomic, assign) NSInteger constMsgType;
@end

@implementation DDLiveRtmpChunk

- (instancetype)initWithDelegate:(id<DDLiveRtmpChunkDelegate>)aDelegate {
    if (self = [super init]) {
        self.delegate     = aDelegate;
        self.maxChunkSize = 128;
        self.tmpChunks    = [[NSMutableArray alloc]init];
        self.tmpChunkPool = [[NSMutableData alloc]init];
    }
    return self;
}

- (void)apeendChunkStream:(NSData *)dataStream {
    
    if(!dataStream || dataStream.length < kRtmpChunkBasicHeader0Size) return;
    [self.tmpChunkPool appendData:dataStream];
    NSData *currentChunk = self.tmpChunkPool;
    
    DDLiveRtmpChunkBasicHeader0 chunkHeader;
    [currentChunk getBytes:&chunkHeader length:sizeof(chunkHeader)];

    // 一个标准的消息
    if(chunkHeader.chunkType == kRtmpChunkTypeFullMessage) {
        
        if (currentChunk.length < kRtmpChunkBasicHeader0Size + kRtmpChunkMessageHeader0Size) {
            NSLog(@"Waitting for a Complete chunk");
            return;
        }
        
        DDLiveRtmpChunkMessageHeader0 messageHeader;
        NSRange headerRange = NSMakeRange(kRtmpChunkBasicHeader0Size, kRtmpChunkMessageHeader0Size);
        [currentChunk getBytes:&messageHeader range:headerRange];
        self.firstMsgLength   = messageHeader.messageLength.data;
        self.currentMsgLength = self.firstMsgLength;
        self.constMsgType     = messageHeader.messageType;
        
        // 有子消息包
        NSInteger messageLength = currentChunk.length - kRtmpChunkBasicHeader0Size - kRtmpChunkMessageHeader0Size;
        if (self.firstMsgLength > messageLength) {
            NSLog(@"Waitting for multiple chunks");
            self.lastMsgLength  = self.currentMsgLength - messageLength;
            [self.tmpChunks removeAllObjects];
            [self.tmpChunks addObject:currentChunk];
            return;
        }
        
        // 是一个完整的消息包
        DDLiveRtmpMessage *message = [[DDLiveRtmpMessage alloc]initWithChunks:@[currentChunk]];
        if (self.delegate && [(id)self.delegate respondsToSelector:@selector(didGetMessage:)]){
            [self.delegate didGetMessage:message];
        }
    }
    // 具有可变大小的消息
    else if(chunkHeader.chunkType == kRtmpChunkTypeSameStreamMessage) {
        
        if (currentChunk.length < kRtmpChunkBasicHeader0Size + kRtmpChunkMessageHeader1Size) {
            NSLog(@"Waiting For a Complete chunk");
            return;
        }
        
        DDLiveRtmpChunkMessageHeader1 messageHeader;
        NSRange headerRange = NSMakeRange(kRtmpChunkBasicHeader0Size, kRtmpChunkMessageHeader1Size);
        [currentChunk getBytes:&messageHeader range:headerRange];
        self.currentMsgLength = messageHeader.messageLength.data;
        
        NSInteger messageLength = currentChunk.length - kRtmpChunkBasicHeader0Size - kRtmpChunkMessageHeader1Size;
        if (self.currentMsgLength > messageLength) {
            NSLog(@"Waitting for more chunks");
            self.lastMsgLength = self.currentMsgLength - messageLength;
            [self.tmpChunks removeAllObjects];
            [self.tmpChunks addObject:currentChunk];
            return;
        }
        
        DDLiveRtmpMessage *message = [[DDLiveRtmpMessage alloc]initWithChunks:@[currentChunk]];
        if (self.delegate && [(id)self.delegate respondsToSelector:@selector(didGetMessage:)]){
            [self.delegate didGetMessage:message];
        }
    }
    // 具有常量大小的消息
    else if(chunkHeader.chunkType == kRtmpChunkTypeSameSizeMessage) {
        
        if (currentChunk.length < kRtmpChunkBasicHeader0Size + kRtmpChunkMessageHeader2Size) {
            NSLog(@"Waiting For a Complete chunk");
            return;
        }
        
        NSInteger messageLength = currentChunk.length - kRtmpChunkBasicHeader0Size - kRtmpChunkMessageHeader2Size;
        if (self.currentMsgLength > messageLength) {
            NSLog(@"Waitting for more chunks");
            self.lastMsgLength = self.currentMsgLength - messageLength;
            [self.tmpChunks removeAllObjects];
            [self.tmpChunks addObject:currentChunk];
            return;
        }
        
        DDLiveRtmpMessage *message = [[DDLiveRtmpMessage alloc]initWithChunks:@[currentChunk]];
        message.type = self.constMsgType;
        if (self.delegate && [(id)self.delegate respondsToSelector:@selector(didGetMessage:)]){
            [self.delegate didGetMessage:message];
        }
    }
    // 子消息,多个chunk组成一个消息
    else if(chunkHeader.chunkType == kRtmpChunkTypeAggregateMessage) {
        
        NSInteger messageLength = currentChunk.length - kRtmpChunkBasicHeader0Size;
        if (self.lastMsgLength > messageLength) {
            NSLog(@"Waitting for more chunks");
            self.lastMsgLength -= messageLength;
            [self.tmpChunks addObject:currentChunk];
            return;
        }
        
        DDLiveRtmpMessage *message = [[DDLiveRtmpMessage alloc]initWithChunks:self.tmpChunks];
        if (self.delegate && [(id)self.delegate respondsToSelector:@selector(didGetMessage:)]){
            [self.delegate didGetMessage:message];
        }
        [self.tmpChunks removeAllObjects];
    }
    
    [self.tmpChunkPool replaceBytesInRange:NSMakeRange(0, self.tmpChunkPool.length) withBytes:NULL length:0];
}

- (void)packageChunkWithMessage:(NSData *)messageData
                messageStreamID:(uint32_t)streamID
                    messageType:(uint8_t)type
                      timestamp:(NSTimeInterval)timestamp
                      chunkType:(uint8_t)chunkType
                  chunkStreamID:(uint8_t)chunkStreamID {
    DDLiveRtmpChunkBasicHeader0 basicHeader;
    basicHeader.chunkType     = chunkType;
    basicHeader.chunkStreamID = chunkStreamID;
    NSData *basicHeaderData = [NSData dataWithBytes:&basicHeader length:sizeof(basicHeader)];
    
    NSData *exTimestampData = nil;
    uint32_t exTimestamp = 0;
    if(timestamp > 0xffffff) {
        exTimestamp = timestamp;
        exTimestampData = [NSData dataWithBytes:&exTimestamp length:sizeof(exTimestamp)];
    }
    
    NSData *messageHeaderData = nil;
    switch (chunkType) {
        case kRtmpChunkTypeFullMessage:{
            DDLiveRtmpChunkMessageHeader0 messageHeader;
            messageHeader.messageLength.data = (uint)messageData.length;
            messageHeader.messageType    = type;
            messageHeader.streamID       = streamID;
            messageHeader.timestamp.data = (uint)(exTimestamp == 0) ? timestamp : 0xffffff;
            messageHeaderData = [NSData dataWithBytes:&messageHeader length:sizeof(messageHeader)];
            break;
        }
        case kRtmpChunkTypeSameStreamMessage:{
            DDLiveRtmpChunkMessageHeader1 messageHeader;
            messageHeader.messageLength.data  = (uint)messageData.length;
            messageHeader.timestampDelta.data = (uint)(exTimestamp == 0) ? timestamp : 0xffffff;
            messageHeader.messageType = type;
            messageHeaderData = [NSData dataWithBytes:&messageHeader length:sizeof(messageHeader)];
            break;
        }
        case kRtmpChunkTypeSameSizeMessage: {
            DDLiveRtmpChunkMessageHeader2 messageHeader;
            messageHeader.timestampDelta.data = (uint)(exTimestamp == 0) ? timestamp : 0xffffff;
            messageHeaderData = [NSData dataWithBytes:&messageHeader length:sizeof(messageHeader)];
            break;
        }
        default:
            break;
    }
    
    NSMutableData *data = [[NSMutableData alloc]init];
    [data appendData:basicHeaderData];
    [data appendData:messageHeaderData];
    if(exTimestampData) {
        [data appendData:exTimestampData];
    }
    
    // 数据包需要切片
    if(messageData.length > self.maxChunkSize) {
        // 第一个数据包
        NSData *firstChunkData = [messageData subdataWithRange:NSMakeRange(0, self.maxChunkSize)];
        [data appendData:firstChunkData];
        if (self.delegate && [(id)self.delegate respondsToSelector:@selector(didPackageChunk:)]) {
            [self.delegate didPackageChunk:data];
        }
        
        // 剩下的数据
        NSInteger lastDataLength = messageData.length - self.maxChunkSize;
        NSInteger loc = self.maxChunkSize;
        basicHeader.chunkType = kRtmpChunkTypeAggregateMessage;
        basicHeaderData = [NSData dataWithBytes:&basicHeader length:sizeof(basicHeader)];
        do {
            data = [[NSMutableData alloc]init];
            NSData *partMessageData = nil;
            if(lastDataLength > self.maxChunkSize) {
                partMessageData = [messageData subdataWithRange:NSMakeRange(loc, self.maxChunkSize)];
                loc += self.maxChunkSize;
                lastDataLength -= self.maxChunkSize;
            }
            else {
                partMessageData = [messageHeaderData subdataWithRange:NSMakeRange(loc, lastDataLength)];
                lastDataLength = 0;
            }
            
            [data appendData:basicHeaderData];
            [data appendData:partMessageData];
            if (self.delegate && [(id)self.delegate respondsToSelector:@selector(didPackageChunk:)]) {
                [self.delegate didPackageChunk:data];
            }
        } while (lastDataLength);
        return;
    }
    
    // 数据包不需要切片
    NSData *fullChunkData = [messageData subdataWithRange:NSMakeRange(0, messageData.length)];
    [data appendData:fullChunkData];
    if (self.delegate && [(id)self.delegate respondsToSelector:@selector(didPackageChunk:)]) {
        [self.delegate didPackageChunk:data];
    }
}

@end
