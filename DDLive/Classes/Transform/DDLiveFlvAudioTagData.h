//
//  DDLiveFlvAudioTagData.h
//  DDLive
//
//  Created by David on 2018/5/15.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import "DDLiveFlvTagData.h"

typedef NS_ENUM(NSInteger,FlvAudioCodecType) {
    kFlvAudioCodecTypeLPCMPlatformEndian    = 0,
    kFlvAudioCodecTypeADPCM                 = 1,
    kFlvAudioCodecTypeMP3                   = 2,
    kFlvAudioCodecTypeLPCMLittleEndian      = 3,
    kFlvAudioCodecTypeNellyMoser16kHzMono   = 4,
    kFlvAudioCodecTypeNellyMoser8kHzMono    = 5,
    kFlvAudioCodecTypeNellyMoser            = 6,
    kFlvAudioCodecTypeG711ALaw              = 7,
    kFlvAudioCodecTypeG711MuLaw             = 8,
    kFlvAudioCodecTypeReserve               = 9,
    kFlvAudioCodecTypeAAC                   = 10,
    kFlvAudioCodecTypeMP38KHz               = 14,
    kFlvAudioCodecTypeDeviceSpecificSound   = 15
};

typedef NS_ENUM(NSInteger,FlvAudioSampleRateType) {
    kFlvAudioSampleRateType55000Hz      = 0,
    kFlvAudioSampleRateType11kHz        = 1,
    kFlvAudioSampleRateType22kHz        = 2,
    kFlvAudioSampleRateType44kHz        = 3
};

typedef NS_ENUM(NSInteger,FlvAudioAccuracyType) {
    kFlvAudioAccuracyTypeType8bits    = 0,
    kFlvAudioAccuracyTypeType16bits   = 1,
};

typedef NS_ENUM(NSInteger,FlvAudioType) {
    kFlvAudioTypeSndMono    = 0,
    kFlvAudioTypeSndStereo  = 1
};

typedef struct {
    unsigned char codecType      : 4;
    unsigned char sampleRateType : 2;
    unsigned char accuracyType   : 1;
    unsigned char audioType      : 1;
} AudioTagDataParameter;

@interface DDLiveFlvAudioTagData : DDLiveFlvTagData

@property (nonatomic, assign) AudioTagDataParameter para;
@property (nonatomic, strong) NSData *paraData;
@property (nonatomic, strong) NSData *metaData;

- (instancetype)initWithAudioPara:(AudioTagDataParameter)para
                        mediaData:(NSData *)mediaData;

@end
