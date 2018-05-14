//
//  DDLiveFlvMixer.h
//  DDLive
//
//  Created by Ming on 2018/5/11.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDLiveFlvTag.h"

@protocol DDLiveFlvMixerDelegate

- (void)didMixFlvTag:(DDLiveFlvTag *)tag;

@end

@interface DDLiveFlvMixer : NSObject

@property (nonatomic, weak) id<DDLiveFlvMixerDelegate> delegate;
@property (nonatomic, strong) NSData *header;
@property (nonatomic, strong) NSMutableData *body;

@end
