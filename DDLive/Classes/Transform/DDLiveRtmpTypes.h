//
//  DDLiveRtmpTypes.h
//  DDLive
//
//  Created by David on 2018/5/19.
//  Copyright © 2018年 David.Dai. All rights reserved.
//

#ifndef DDLiveRtmpTypes_h
#define DDLiveRtmpTypes_h

#pragma pack(push, 1) //字节对齐 为1

/**
 * RTMP在发送chunk前需要完成握手流程
 * ｜client｜Server ｜
 * ｜－－－C0+C1—->  |
 * ｜<－－S0+S1+S2–- |
 * ｜－－－C2-－－－> ｜
 * c0,s0:版本号(1个字节)，数据固定为0x03（开源版本）
 * c1,s1:时间戳(4个字节) + 保留(4个字节) + 随机数(1528个字节)
 * c2,s2:s1或c1的数据(1536个字节)
 *
 * RTMP数据块由chunk组成
 * chunk又由chunkHeader + chunkData组成
 * chunkHeader由chunkBasicHeader（可变）+ MessageHeader（可变）+ ExtendedTimestamp（4个字节或者无）组成
 * chunkData填充Message(1个Message可分解为多个chunk)
 */

#define kRtmpHandshakeRandomDataSize      1528
#define kRtmpChunkBasicHeader0Size        1
#define kRtmpChunkMessageHeader0Size      11
#define kRtmpChunkMessageHeader1Size      7
#define kRtmpChunkMessageHeader2Size      3

typedef struct {
    uint data : 24;
} uint24_t;

typedef struct {
    uint8_t chunkType     : 2;    // 表示chunk类型
    uint8_t chunkStreamID : 6;    // csid:[3，63］0~2协议保留，块的id可根据这个值来区分开不同的数据流或者控制流
} DDLiveRtmpChunkBasicHeader0;    // 常规的rtmp应用使用basicHeader0版本

typedef struct {
    uint8_t chunkType : 2;
    uint8_t reserve   : 6;
    uint8_t chunkStreamID;
} DDLiveRtmpChunkBasicHeader1;

typedef struct {
    uint8_t  chunkType : 2;
    uint8_t  reserve   : 6;
    uint16_t chunkStreamID;
} DDLiveRtmpChunkBasicHeader2;

typedef struct {
    uint24_t  timestamp;          // 当溢出时全置为1，并生成ExtendedTimestamp字段（4个字节）
    uint24_t  messageLength;      // 表示Message长度
    uint8_t   messageType;        // 消息的类型
    uint32_t  streamID;           // 流id
} DDLiveRtmpChunkMessageHeader0;
// chunkType:0 表示一个全新的消息

typedef struct {
    uint24_t  timestampDelta;     //存储的是和上一个chunk的时间差。当溢出时，实际的时间戳差值就会转存到Extended Timestamp字段中
    uint24_t  messageLength;
    uint8_t   messageType;
} DDLiveRtmpChunkMessageHeader1;
// chunkType:1 表示此chunk和上一次发的chunk所在的流相同

typedef struct {
    uint24_t  timestampDelta;
} DDLiveRtmpChunkMessageHeader2;
// chunkType:2 表示此chunk和上一次发送的chunk所在的流、消息的长度和消息的类型都相同
// chunkType:3 表示messageHeader和上一个message相同

#pragma pack(pop)//恢复字节对齐

typedef NS_ENUM(NSUInteger, RtmpChunkType) {
    kRtmpChunkTypeFullMessage       = 0, // 必须使用在一个流的开始
    kRtmpChunkTypeSameStreamMessage = 1, // 用于单个的视频消息
    kRtmpChunkTypeSameSizeMessage   = 2, // 用于单个的音频消息
    kRtmpChunkTypeAggregateMessage  = 3  // 用于被拆分的子消息
};

typedef NS_ENUM(NSUInteger, RtmpChunkStreamID) {
    kRtmpChunkStreamIDControl   = 0x02, // 控制流(协议规定保留)
    kRtmpChunkStreamIDText      = 0x03, // 作为文本流
    kRtmpChunkStreamIDMedia     = 0x04, // 作为多媒体流
};

typedef NS_ENUM(NSUInteger, RtmpMsgType) {
    // 控制流中的Message类型
    kRtmpMsgTypeSetChunkSize      = 1, // 用于通知对端一个新的最大chunk大小。                     内容:1位reserve 31位chunkSize最大值只能为0xFFFFFF类型(四个字节)
    kRtmpMsgTypeAbort             = 2, // 应用程序可以在关闭时发送此消息，以指示不需要进一步处理消息。  内容:ChunkStreamID(四个字节)
    kRtmpMsgTypeAcknowledgement   = 3, // 当收到本地窗口大小的数据时向对方发送ack。                 内容:目前为止接收到的字节数(四个字节)
    kRtmpMsgTypeUserControl       = 4, // 客户端和服务器发送此消息把用户控制事件通知对端。            内容:用户控制事件类型(两个字节)和事件数据
    kRtmpMsgTypeWindowAckSize     = 5, // 向对方发送本地维护的窗口大小，只有在收到ack后才会继续发送数据.内容:本地窗口大小（四个字节）
    kRtmpMsgTypeSetPeerBandwidth  = 6, // 设置对方的窗口大小。                                   内容:4个字节窗口大小+1个字节limit类型
    
    // 媒体流中的Message类型
    kRtmpMsgTypeAudio             = 8,
    kRtmpMsgTypeVideo             = 9,
    
    // 文本流中的Message类型
    kRtmpMsgTypeDataMessageAMF3   = 15, // AMF3格式的用户自定义信息
    kRtmpMsgTypeSharedObjectAMF3  = 16, // AMF3格式的共享Flash对象
    kRtmpMsgTypeCommandAMF3       = 17, // AMF3格式的命令消息（NetConnection和NetStream）
    kRtmpMsgTypeDataMessageAMF0   = 18,
    kRtmpMsgTypeSharedObjectAMF0  = 19,
    kRtmpMsgTypeCommandAMF0       = 20,
    kRtmpMsgTypeAggregate         = 22,
};

typedef NS_ENUM(NSUInteger, AMFDataType) {
    kAMFDataTypeNumber      = 0x00,
    kAMFDataTypeBOOL        = 0x01,
    kAMFDataTypeString      = 0x02,
    kAMFDataTypeObject      = 0x03,
    kAMFDataTypeNull        = 0x05,
    kAMFDataTypeUndefined   = 0x06,
    kAMFDataTypeReference   = 0x07,
    kAMFDataTypeMixedArray  = 0x08,
    kAMFDataTypeObjectEnd   = 0x09,
    kAMFDataTypeArray       = 0x0a,
    kAMFDataTypeDate        = 0x0b,
    kAMFDataTypeLongString  = 0x0c,
    kAMFDataTypeUnsupported = 0x0d,
};

#endif /* DDLiveRtmpTypes_h */
