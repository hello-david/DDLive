//
//  DDLiveAACEncoder.h
//  DDLive
//
//  Created by Ming on 2018/5/11.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDLiveCodecTools.h"

@interface DDLiveAACEncoder : NSObject

- (void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer
           completionBlock:(void (^)(NSData * encodedData, NSError* error))completionBlock;

@end
