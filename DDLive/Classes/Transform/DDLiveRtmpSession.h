//
//  DDLiveRtmpSession.h
//  DDLive
//
//  Created by David on 2018/5/20.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import "DDLiveRtmpTypes.h"
#import "DDLiveRtmpMessage.h"
#import "DDLiveRtmpChunk.h"

typedef NS_ENUM(NSInteger,RtmpSessionState) {
    kRtmpSessionStateNone,
    kRtmpSessionStateSocketConnected,
    
    kRtmpSessionStateHandshakeStart,
    kRtmpSessionStateHandshakeAck,
    kRtmpSessionStateHandshakeComplete,
};

@protocol DDLiveRtmpSessionDelegate

- (void)didRtmpSessionStateChange:(RtmpSessionState)state;

@end

@interface DDLiveRtmpSession : NSObject <GCDAsyncSocketDelegate,DDLiveRtmpChunkDelegate>
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, assign) RtmpSessionState state;
@property (nonatomic, strong) DDLiveRtmpChunk *chunkManager;

- (void)connectToHost:(NSString *)host port:(NSInteger)port;
- (void)disConnect;

@end
