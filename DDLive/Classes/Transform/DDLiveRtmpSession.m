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
@property (nonatomic, strong) NSMutableData *tmpPool;

@end

@implementation DDLiveRtmpSession

- (instancetype)init {
    if(self = [super init]) {
        self.socketQueue = dispatch_queue_create("com.rtmpSocketQueue", NULL);
        self.socket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:_socketQueue];
        self.chunkManager = [[DDLiveRtmpChunk alloc]initWithDelegate:self];
        self.tmpPool = [[NSMutableData alloc]init];
    }
    return self;
}

- (void)connectToHost:(NSString *)host port:(NSInteger)port{

    NSError *error = nil;
    NSURL *url = [[NSURL alloc]initWithString:@"rtmp://live.hkstv.hk.lxdns.com/live/hks"];
    [self.socket connectToHost:@"live.hkstv.hk.lxdns.com" onPort:1935 error:&error];
    if(error){
        NSLog(@"%@",error);
    }
}

- (void)disConnect {
    
}

#pragma mark - Implementation detail
- (void)handshakeStart {
    //c0
    char version = 0x03;
    NSData *c0   = [NSData dataWithBytes:&version length:1];
    
    //c1
    UInt32 timestamp = (UInt32)[[NSDate date]timeIntervalSince1970] * 1000;
    UInt32 reserve   = 0;
    uint8_t *randomBytes = (uint8_t *)malloc(kRtmpHandshakeRandomDataSize);
    NSMutableData *c1    = [NSMutableData dataWithBytes:&timestamp length:sizeof(timestamp)];
    [c1 appendBytes:&reserve length:sizeof(reserve)];
    [c1 appendBytes:randomBytes length:kRtmpHandshakeRandomDataSize];
    
    NSMutableData *c0c1 = [NSMutableData dataWithData:c0];
    [c0c1 appendData:c1];
    [self.socket writeData:c0c1 withTimeout:-1 tag:1];
    
    self.state = kRtmpSessionStateHandshakeStart;
}

- (void)handshakeFlowCheckWithData:(NSData *)data {
    if(self.state == kRtmpSessionStateHandshakeStart) {
        // c2
        NSData *sendTimestamp = [data subdataWithRange:NSMakeRange(1, 4)];
        UInt32 timestamp      = (UInt32)[[NSDate date]timeIntervalSince1970] * 1000;
        uint8_t *randomBytes  = (uint8_t *)malloc(kRtmpHandshakeRandomDataSize);
        
        NSMutableData *c2 = [NSMutableData dataWithData:sendTimestamp];
        [c2 appendBytes:&timestamp length:sizeof(timestamp)];
        [c2 appendBytes:randomBytes length:kRtmpHandshakeRandomDataSize];
        
        [self.socket writeData:c2 withTimeout:-1 tag:1];
        self.state = kRtmpSessionStateHandshakeAck;
        return;
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
    NSInteger s1Length = kRtmpHandshakeRandomDataSize + 4 + 4;
    NSInteger s2Length = s1Length;
    NSInteger s0Length = 1;
    [self.tmpPool appendData:data];
    if(self.tmpPool.length == s0Length + s1Length + s2Length) {
        [self handshakeFlowCheckWithData:data];
    }
    
    [self.socket readDataWithTimeout:-1 tag:3];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    [self.socket readDataWithTimeout:-1 tag:2];
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    [self handshakeStart];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    
}
@end
