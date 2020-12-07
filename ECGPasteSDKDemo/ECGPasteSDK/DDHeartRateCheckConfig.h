//
//  DDHeartRateCheckConfig.h
//  healthCheck
//
//  Created by admin on 2019/10/21.
//  Copyright © 2019 xlf. All rights reserved.
//

#ifndef DDHeartRateCheckConfig_h
#define DDHeartRateCheckConfig_h

typedef enum DDBLECommandType {
    DDBLECommandTypeError               =0,             //错误命令包含0xE8 0xFF 00000000 和0xE8 + 命令     000000000
    DDBLECommandTypeQueryState              ,           //查询设备状态0xE8    0x10
    DDBLECommandTypeQueryMachineFactoryInfo,            //查询出厂信息0xE8    0x12
    DDBLECommandTypeQueryMachineModel,                  //查询机器型号0xE8    0x13
    DDBLECommandTypeQueryElectrodeConnectState,         //查询电极连接状态0xE8    0x15
    DDBLECommandTypeQueryErrorCode,                     //查询错误码0xE8    0x16
    DDBLECommandTypeQueryMachineMac,                    //查询设备mac地址0xE8    0x1B
    DDBLECommandTypeQueryBindUserID,                    //查询bind用户id0xE8    0x1D
    DDBLECommandTypeQueryMachineDate,                   //查询设备时间0xE8    0x1F
    DDBLECommandTypeLiveECG,                            //实时传输0xE8    0x20
    DDBLECommandTypeTurnOffCollect,                     //结束单机采集0xE8    0x22
    DDBLECommandTypeStartCollect,                       //开始单机采集0xE8    0x23
    DDBLECommandTypeTurnOffLiveECG,                     //停止实时传输0xE8    0x26
    DDBLECommandTypeSubscribeTime,                      //装订时间0xE8    0x40 
    DDBLECommandTypeBindUserID,                         //bind用户ID 0xE8    0x41
    DDBLECommandTypeForceReset,                        //强制复位 内部命令0xE8    0x55
    DDBLECommandTypeResponseLiveECG,                    //实时ECG数据的reponse头4字节，暂时归为命令管理
    DDBLECommandTypeUnknown
}DDBLECommandType;



#define DDMachineBlueConfigUUID @"A6A958E5-813D-AE26-1399-3A029C27A3DF" //设备配置UUID

#define DDMachineBlueReceiveUUID  @"0000ffe1-0000-1000-8000-00805f9b34fb" //设备读取UUID

#define DDMachineBlueSendUUID @"0000ffe1-0000-1000-8000-00805f9b34fb" //设备写入UUID

#define DDCommondRetryTimes                3    //指令重试次数

#define DDMachineBlue4Name @"ECG-A000"   // 设备名称4.3

#define DDMachineBlue5Name @"BW-ECG-01"   // 设备名称5.0

//s蓝牙设备服务特征定义 fff0是服务   fff1是读取  fff2是发送
#define DDMachineBlueServiceUUID @"FFF0" //设备服务ID

#define DDBlue4CharacteristicsRead       @"FFF1"

#define DDBlue4CharacteristicsSend       @"FFF2"

//5.0是采用通知特征 4.3是采用读d特征，其实是一样的
#define DDBlue5CharacteristicsRead       @"FFF2"

#define DDBlue5CharacteristicsSend       @"FFF1"

/*
 查询状态指令:
 H=0        K=4
 A:电池编码
 B: 0x03：单机采集、0x02：同步采集、0x01：实时采集、0x00：待机
 电量：X:采样值高8位   、Y:采样值低8位  （注：电量百分比由应用端计算）
 */
#define DDECGCommandQueryState                          @"e810" //0xE8    0x10 返回数据字段 A,B,X,Y

/*
 查询设备出厂信息
 H=0        K=11
 S[0：10]：设备出厂信息（共11字节，ASCII）
 */
#define DDECGCommandQueryMachineFactoryInfo             @"e812" //0xE8    0x12  返回数据字段 S[0：10]
/*
 查询设备型号
 H=0        K=14
 E[0：13]：设备型号（共14字节，ASCII）
 */
#define DDECGCommandQueryMachineModel                   @"e813" //0xE8    0x13  返回数据字段 E[0：13]：设备型号（共14字节，ASCII）
/*
 查询电极连接状态
 导联状态（心电专用）。1：脱落；2：连接；0：未识别
 A:VL+          B:VR+           C:V-            D:ELL
 */
#define DDECGCommandQueryElectrodeConnectState          @"e815" //0xE8    0x15  返回数据字段 A,B,C,D
/*
 查询错误码
 H=0
 K=4
 X=1:FLASH异常
 Y=1:ADSxx异常
 A=1: 蓝牙异常
 */
#define DDECGCommandQueryErrorCode                      @"e816" //0xE8    0x16  返回数据字段 X,Y,A,0x00

/*
 查询设备MAC地址
 H=0    K=6
 [D0:D5]：MAC地址（共6字节）
 */
#define DDECGCommandQueryMachineMac                     @"e81b" //0xE8    0x1B  返回数据字段  [D0:D5]：MAC地址（共6字节）

/*
 查询当前绑定用户ID
 H=0    K=18
 [D0:D17]：用户ID（共18字节，ASCII）
 */
#define DDECGCommandQueryBindUserID                     @"e81d" //0xE8    0x1D  返回数据字段  [D0:D17]：用户ID（共18字节，ASCII）
/*
 查询设备时间
 H=0    K=6
 [D0:D5]：设备时间（共6字节）
 */
#define DDECGCommandQueryMachineDate                    @"e81f" //0xE8    0x1F  返回数据字段   [D0:D5]：设备时间（共6字节）
/*
 开始单机采集
 H=6        K=4
 Y:年、M:月、D:日、H:时、F:分、S:秒
 A=1：成功     A=0：失败
 */
#define DDECGCommandStartCollect                        @"e823" //0xE8    0x23 参数：Y,M,D,H,F,S 返回数据字段   0x00,0x00,0x00,A
/*
 结束单机采集
 H=0        K=4
 A=1：成功     A=0：失败
 */
#define DDECGCommandTurnOffCollect                      @"e822" //0xE8    0x22 返回数据字段   0x00,0x00,0x00,A
/*
 实时传输
 H=4
 A：通道号
 传输时间（单位：ms）：H:高字节      M:中字节   L:低字节   （传输时间=0时发默认30s）
 */
#define DDECGCommandLiveECG                             @"e820" //0xE8    0x20  参数：A,H,M,L 返回数据字段  以1次/100ms的频率返回FDFE开头的ECG数据
/*
 停止实时传输
 H=0        K=4
 A=1：成功     A=0：失败
 */
#define DDECGCommandTurnOffLiveECG                      @"e826" //0xE8    0x26  0x00,0x00,0x00,A
/*
 装订时间
 H=6        K=4
 Y:年、M:月、D:日、H:时、F:分、S:秒
 A=1：成功 A=0：失败
 */
#define DDECGCommandSubscribeTime                       @"e840" //0xE8    0x40  参数：Y,M,D,H,F,S 返回数据字段   0x00,0x00,0x00,A
/*
 绑定用户ID
 H=18       K=4
 [D0:D17]：用户ID（共18字节，ASCII）
 A=1：成功     A=0：失败
 */
#define DDECGCommandBindUserId                          @"e841" //0xE8    0x41  参数：[D0:D17]：用户ID（共18字节，ASCII) 返回数据字段   0x00,0x00,0x00,A
/*
 强制MCU复位(内部调试不对外开放)
 H=0        K=4
 A=1：成功     A=0：失败
 */
#define DDECGCommandForceReset                          @"e855" //0xE8    0x55  返回数据字段   0x00,0x00,0x00,A

/*
 设备回复“E8 FF 00 00 00 00”，表示指令有误（长度不足、命令字不存在、逻辑错误）
 设备回复“E8 命令字 00 00 00 00”，表示指令执行失败（索要数据不存在、当前时刻不适合执行此命令、设备错误）
 数据上行（设备到主机）通路被占用时，主机发送指令设备不响应
 */
/*
 指令有误（回复指令）
 H=0        K=4
 A=1：成功     A=0：失败
 */
#define DDECGCommandError                           @"e8ff" //0xE8    0xFF
/*
 实时传输数据的相应数据
 */
#define DDECGCommandResponseLiveECG                          @"fdfe" //0xFD    0xFE

#endif /* DDHeartRateCheckConfig_h */
