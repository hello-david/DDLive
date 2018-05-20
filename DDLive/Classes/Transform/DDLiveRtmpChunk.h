//
//  DDLiveRtmpChunk.h
//  DDLive
//
//  Created by David on 2018/5/19.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDLiveRtmpMessage.h"

@protocol DDLiveRtmpChunkDelegate

- (void)didGetMessage:(DDLiveRtmpMessage *)message;
- (void)didPackageChunk:(NSData *)data;

@end

@interface DDLiveRtmpChunk : NSObject

@property (nonatomic, assign) NSInteger maxChunkSize;
@property (nonatomic, weak) id<DDLiveRtmpChunkDelegate> delegate;

- (instancetype)initWithDelegate:(id <DDLiveRtmpChunkDelegate>)aDelegate;
- (void)apeendChunkStream:(NSData *)chunkStream;
- (void)packageChunkWithMessage:(NSData *)messageData
                messageStreamID:(uint32_t)streamID
                    messageType:(uint8_t)type
                      timestamp:(NSTimeInterval)timestamp// or timestamp delta
                      chunkType:(uint8_t)chunkType
                  chunkStreamID:(uint8_t)chunkStreamID;

@end
