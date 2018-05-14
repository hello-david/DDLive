//
//  DDLiveFlvAudioTagData.m
//  DDLive
//
//  Created by David on 2018/5/15.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import "DDLiveFlvAudioTagData.h"

@implementation DDLiveFlvAudioTagData

- (instancetype)initWithAudioPara:(AudioTagDataParameter)para mediaData:(NSData *)mediaData {
    if(self = [super init]) {
        self.para       = para;
        self.paraData   = [NSData dataWithBytes:&para length:sizeof(para)];
        self.metaData   = mediaData;
    }
    return self;
}

- (instancetype)initWithTagData:(NSData *)tagData {
    if(self = [super initWithTagData:tagData]) {
        if(tagData.length > 1) {
            [tagData getBytes:&_para length:sizeof(_para)];
            self.paraData   = [tagData subdataWithRange:NSMakeRange(0, 1)];
            self.metaData   = [tagData subdataWithRange:NSMakeRange(1, tagData.length - 1)];
        }
    }
    return self;
}

- (NSData *)data {
    NSMutableData *data = [[NSMutableData alloc]init];
    [data appendData:self.paraData];
    [data appendData:self.metaData];
    self.tagData = data;
    return data;
}
@end
