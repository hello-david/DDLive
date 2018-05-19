//
//  DDLiveRtmpPublisher.h
//  DDLive
//
//  Created by Ming on 2018/5/11.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

@protocol DDLiveRtmpPublisherDelegate

@end

@interface DDLiveRtmpPublisher : NSObject

@property (nonatomic, copy) NSString *url;
@property (nonatomic, weak) id<DDLiveRtmpPublisherDelegate> delegate;

- (instancetype)initWithDelegate:(id<DDLiveRtmpPublisherDelegate>)aDelegate;

@end
