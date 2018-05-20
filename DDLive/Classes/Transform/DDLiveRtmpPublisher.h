//
//  DDLiveRtmpPublisher.h
//  DDLive
//
//  Created by Ming on 2018/5/11.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import "DDLiveRtmpSession.h"

@protocol DDLiveRtmpPublisherDelegate <DDLiveRtmpSessionDelegate>

@end

@interface DDLiveRtmpPublisher : DDLiveRtmpSession

@property (nonatomic, weak) id<DDLiveRtmpPublisherDelegate> delegate;

- (instancetype)initWithDelegate:(id<DDLiveRtmpPublisherDelegate>)aDelegate;
- (void)sendFrame:(NSData *)flvFrame;

@end
