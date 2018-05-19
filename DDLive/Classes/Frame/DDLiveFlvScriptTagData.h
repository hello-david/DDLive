//
//  DDLiveFlvScriptTagData.h
//  DDLive
//
//  Created by David on 2018/5/15.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#import "DDLiveFlvTagData.h"
/**
 *  Script Info的词典常用内容
 *  duration        时长
 *  width           视频宽度
 *  height          视频高度
 *  videodatarate   视频码率
 *  framerate       视频帧率
 *  videocodecid    视频编码方式
 *  audiosamplerate 音频采样率
 *  audiosamplesize 音频采样精度
 *  stereo          是否为立体声
 *  audiocodecid    音频编码方式
 *  filesize        文件大小
 */

@interface DDLiveFlvScriptTagData : DDLiveFlvTagData

@property (nonatomic, strong) NSDictionary *infoDic;

- (instancetype)initWithInfo:(NSDictionary *)infoDic;

@end
