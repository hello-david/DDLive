//
//  DDLiveFlvTagData.m
//  DDLive
//
//  Created by David on 2018/5/15.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import "DDLiveFlvTagData.h"

@implementation DDLiveFlvTagData

- (instancetype)initWithTagData:(NSData *)tagData {
    if(self = [super init]) {
        self.tagData = tagData;
    }
    return self;
}

- (NSData *)data {
    return self.tagData;
}

@end
