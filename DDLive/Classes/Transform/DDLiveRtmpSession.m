//
//  DDLiveRtmpSession.m
//  DDLive
//
//  Created by David on 2018/5/20.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import "DDLiveRtmpSession.h"

@interface DDLiveRtmpSession()

@property (nonatomic, strong) GCDAsyncSocket *socket;
@property (nonatomic, strong) dispatch_queue_t socketQueue;

@end

@implementation DDLiveRtmpSession

- (instancetype)init {
    if(self = [super init]) {
        self.socketQueue = dispatch_queue_create("com.rtmpSocketQueue", NULL);
        self.socket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:_socketQueue];
        self.chunkManager = [[DDLiveRtmpChunk alloc]initWithDelegate:self];
    }
    return self;
}

- (void)connectToHost:(NSString *)host port:(NSInteger)port{
    if (port <= 0) {
        //RTMP默认端口,1935
        port = 1935;
    }
    
}

- (void)disConnect {
    
}

#pragma mark - Implementation detail
- (void)handshakeStart {
    //c0
    char version = 0x03;
    NSData *c0 = [NSData dataWithBytes:&version length:1];
    [self.socket writeData:c0 withTimeout:-1 tag:1];
    
    //c1
    UInt32 timestamp = (UInt32)[[NSDate date]timeIntervalSince1970] * 1000;
    UInt32 reserve = 0;
    uint8_t *randomBytes = (uint8_t *)malloc(kRtmpHandshakeRandomDataSize);
    NSMutableData *c1 = [NSMutableData dataWithBytes:&timestamp length:sizeof(timestamp)];
    [c1 appendBytes:&reserve length:sizeof(reserve)];
    [c1 appendBytes:randomBytes length:kRtmpHandshakeRandomDataSize];
    [self.socket writeData:c1 withTimeout:-1 tag:1];
    
    self.state = kRtmpSessionStateHandshakeStart;
}

- (void)handshakeFlowCheckWithData:(NSData *)data {
    if(self.state == kRtmpSessionStateHandshakeStart) {
        // s0
        if(data.length == 4) {
        }
        
        // s1
        if(data.length == kRtmpHandshakeRandomDataSize + 4 + 4) {
            // c2
            NSData *sendTimestamp = [data subdataWithRange:NSMakeRange(0, 4)];
            UInt32 timestamp = (UInt32)[[NSDate date]timeIntervalSince1970] * 1000;
            NSMutableData *c2 = [NSMutableData dataWithData:sendTimestamp];
            [c2 appendBytes:&timestamp length:sizeof(timestamp)];
            
            [self.socket writeData:c2 withTimeout:-1 tag:1];
            self.state = kRtmpSessionStateHandshakeAck;
        }
    }
    
    // s2
    if(self.state == kRtmpSessionStateHandshakeAck) {
        self.state = kRtmpSessionStateHandshakeComplete;
    }
}

#pragma mark - ChunkDelegate
- (void)didPackageChunk:(NSData *)data {
    
}

- (void)didGetMessage:(DDLiveRtmpMessage *)message {
    
}

#pragma mark - SocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    [self handshakeFlowCheckWithData:data];
    
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToUrl:(NSURL *)url {
    
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    
}
@end
