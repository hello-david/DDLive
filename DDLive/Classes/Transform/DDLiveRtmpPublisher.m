//
//  DDLiveRtmpPublisher.m
//  DDLive
//
//  Created by Ming on 2018/5/11.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import "DDLiveRtmpPublisher.h"

@interface DDLiveRtmpPublisher()


@end

@implementation DDLiveRtmpPublisher

- (instancetype)initWithDelegate:(id<DDLiveRtmpPublisherDelegate>)aDelegate {
    if (self = [super init]) {
        self.delegate = aDelegate;
    }
    return self;
}

- (void)sendFrame:(NSData *)flvFrame {
    
}

#pragma mark - SocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    [super socket:sock didReadData:data withTag:tag];
    
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    [super socket:sock didWriteDataWithTag:tag];
    
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToUrl:(NSURL *)url {
    [super socket:sock didConnectToUrl:url];
    
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    [super socketDidDisconnect:sock withError:err];
    
}
@end
