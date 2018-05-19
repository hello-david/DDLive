//
//  DDLiveFlvMixer.m
//  DDLive
//
//  Created by Ming on 2018/5/11.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import "DDLiveFlvMixer.h"

@interface DDLiveFlvMixer()

@property (nonatomic, strong) NSData *header;
@property (nonatomic, assign) NSTimeInterval staredTime;

@end

@implementation DDLiveFlvMixer

- (instancetype)initWithDelegate:(id<DDLiveFlvMixerDelegate>)delegate {
    if(self = [super init]) {
        self.delegate = delegate;
        [self initFlvHeader];
    }
    return self;
}

- (void)dealloc {
    self.delegate = nil;
}

- (void)initFlvHeader {
    DDLiveFlvHeader flvHeader;
    [DDLiveFlvTag setUInt24:flvHeader.signature hex:0x464c66];
    flvHeader.version    = 0x01;
    flvHeader.flags      = 0x0a;//0000 0101表示有音频和视频
    flvHeader.headerSize = 9;
    
    self.header = [NSData dataWithBytes:&flvHeader length:sizeof(flvHeader)];
}

- (void)mixFlvData:(DDLiveFlvTagData *)tagData {
    DDLiveFlvPreviosTagSize previosTagSize;
    previosTagSize.size = 0;
    
    // 生成Flv头
    if(!self.isStartMixer) {
        self.isStartMixer = YES;
        self.staredTime = [[NSDate date] timeIntervalSince1970] * 1000;
        if(self.delegate && [(id)self.delegate respondsToSelector:@selector(didMixFlvData:timestmap:)]) {
            [self.delegate didMixFlvData:self.header timestmap:0];
        }
        
        NSData *firstTagSize = [NSData dataWithBytes:&previosTagSize length:sizeof(previosTagSize)];
        if(self.delegate && [(id)self.delegate respondsToSelector:@selector(didMixFlvData:timestmap:)]) {
            [self.delegate didMixFlvData:firstTagSize timestmap:0];
        }
    }
    
    // 生成tag并序列化
    NSTimeInterval currentTimeStmap = [[NSDate date] timeIntervalSince1970] * 1000 - self.staredTime;
    DDLiveFlvTag *tag = [[DDLiveFlvTag alloc]initWithTimestmap:currentTimeStmap tagData:tagData];
    if(self.delegate && [(id)self.delegate respondsToSelector:@selector(didMixFlvData:timestmap:)]) {
        [self.delegate didMixFlvData:tag.data timestmap:currentTimeStmap];
    }
    
    previosTagSize.size = (UInt32)tag.data.length;
    NSData *thisTagSize = [NSData dataWithBytes:&previosTagSize length:sizeof(previosTagSize)];
    if(self.delegate && [(id)self.delegate respondsToSelector:@selector(didMixFlvData:timestmap:)]) {
        [self.delegate didMixFlvData:thisTagSize timestmap:currentTimeStmap];
    }
    
}

@end
