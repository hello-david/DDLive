//
//  DDLiveFlvVideoTagData.h
//  DDLive
//
//  Created by David on 2018/5/15.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import "DDLiveFlvTagData.h"

typedef NS_ENUM(NSInteger,FlvVideoFrameType) {
    kFlvVideoFrameTypeKeyFrame                  = 1,  // (for AVC,a seekable frame)
    kFlvVideoFrameTypeInterFrame                = 2,  // (for AVC,a nonseekable frame)
    kFlvVideoFrameTypeDisposableFrame           = 3,  // disposable inter frame (H.263 only)
    kFlvVideoFrameTypeGeneratedKeyframe         = 4,  // (reserved for serve use only)
    kFlvVideoFrameTypeVideoInfoOrCommandFrame   = 5,  // sps/pps
};

typedef NS_ENUM(NSInteger,FlvVideoCodecType) {
    kFlvVideoCodecTypeJPEG                  = 1,
    kFlvVideoCodecTypeH263                  = 2,
    kFlvVideoCodecTypeScreenVideo           = 3,
    kFlvVideoCodecTypeVP6                   = 4,
    kFlvVideoCodecTypeVP7WithAlphaChannel   = 5,
    kFlvVideoCodecTypeScreenVideoVersion2   = 6,
    kFlvVideoCodecTypeAVC                   = 7
};

typedef struct {
    unsigned char frameType : 4;
    unsigned char codecType : 4;
} VideoTagDataParameter;

@interface DDLiveFlvVideoTagData : DDLiveFlvTagData

@property (nonatomic, assign) VideoTagDataParameter para;
@property (nonatomic, strong) NSData *paraData;
@property (nonatomic, strong) NSData *metaData;

- (instancetype)initWithVideoPara:(VideoTagDataParameter)para
                        mediaData:(NSData *)mediaData;

@end
