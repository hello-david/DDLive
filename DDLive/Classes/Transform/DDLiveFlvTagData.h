//
//  DDLiveFlvTagData.h
//  DDLive
//
//  Created by David on 2018/5/15.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DDLiveFlvTagData : NSObject

@property (nonatomic, strong) NSData *tagData;

- (instancetype)initWithTagData:(NSData *)tagData;

- (NSData *)data;

@end
