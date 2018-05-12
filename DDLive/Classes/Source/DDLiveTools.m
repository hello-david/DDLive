//
//  DDLiveTools.m
//  DDLive
//
//  Created by David on 2018/5/12.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import "DDLiveTools.h"

@implementation DDLiveTools

+ (UIImage *)pixelBufferToImage:(CVPixelBufferRef)pixelBuffer {
    UIImage *image = nil;
    if(CURRENT_SYSTEM_VERSION < 9){
        image = [[UIImage alloc] initWithCIImage:[CIImage imageWithCVPixelBuffer:pixelBuffer]];
    }
    else{
        CGImageRef giImageRef;
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, NULL, &giImageRef);
        image = [UIImage imageWithCGImage:giImageRef];
        CGImageRelease(giImageRef);
    }
    return image;
}
@end
