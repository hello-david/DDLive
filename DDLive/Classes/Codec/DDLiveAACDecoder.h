//
//  DDLiveAACDecoder.h
//  DDLive
//
//  Created by Ming on 2018/5/11.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDLiveCodecTools.h"

@interface DDLiveAACDecoder : NSObject

- (void)decodeAACBuffer:(NSData *)adtsAAC
        completionBlock:(void (^)(NSData * pcmData, NSError* error))completionBlock;
@end
