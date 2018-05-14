//
//  DDLiveFlvScriptTagData.m
//  DDLive
//
//  Created by David on 2018/5/15.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import "DDLiveFlvScriptTagData.h"

@implementation DDLiveFlvScriptTagData

- (instancetype)initWithInfo:(NSDictionary *)infoDic {
    if(self = [super init]) {
        self.infoDic = infoDic;
    }
    return self;
}

- (instancetype)initWithTagData:(NSData *)tagData {
    if(self = [super initWithTagData:tagData]) {
        // AMF1 AMF2 固定表示为onMetaData和数组
        if(tagData.length > 18) {
            NSData *dicData = [tagData subdataWithRange:NSMakeRange(18, tagData.length - 18)];
            NSDictionary *dictionary =[NSJSONSerialization JSONObjectWithData:dicData options:NSJSONReadingMutableLeaves error:nil];
            self.infoDic = dictionary;
        }
    }
    return self;
}

- (NSData *)data {
    NSMutableData *data = [[NSMutableData alloc]init];
    // AMF1
    Byte amfType = 0x02;
    UInt16 amfStringLength = 0x000a;
    NSString *amfString = @"onMetaData";
    [data appendBytes:&amfType length:sizeof(amfType)];
    [data appendBytes:&amfStringLength length:sizeof(amfStringLength)];
    [data appendData:[amfString dataUsingEncoding:NSUTF8StringEncoding]];
    
    // AMF2
    Byte amf2Type = 0x08;
    UInt32 amfDicLength = (UInt32)self.infoDic.count;
    NSData *amfDic = [NSJSONSerialization dataWithJSONObject:self.infoDic options:NSJSONWritingPrettyPrinted error:nil];
    [data appendBytes:&amf2Type length:sizeof(amf2Type)];
    [data appendBytes:&amfDicLength length:sizeof(amfDicLength)];
    [data appendData:amfDic];
    
    return data;
}

@end
