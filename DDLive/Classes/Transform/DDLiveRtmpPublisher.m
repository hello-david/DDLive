//
//  DDLiveRtmpPublisher.m
//  DDLive
//
//  Created by Ming on 2018/5/11.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import "DDLiveRtmpPublisher.h"

@interface DDLiveRtmpPublisher() <GCDAsyncSocketDelegate>

@property (nonatomic, strong) GCDAsyncSocket *socket;
@property (nonatomic, strong) dispatch_queue_t socketQueue;

@end

@implementation DDLiveRtmpPublisher

- (instancetype)initWithDelegate:(id<DDLiveRtmpPublisherDelegate>)aDelegate {
    if (self = [super init]) {
        self.delegate = aDelegate;
        self.socketQueue = dispatch_queue_create("com.rtmpSocketQueue", NULL);
        self.socket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:_socketQueue];
    }
    return self;
}

#pragma mark - SocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToUrl:(NSURL *)url {
    
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    
}
@end
