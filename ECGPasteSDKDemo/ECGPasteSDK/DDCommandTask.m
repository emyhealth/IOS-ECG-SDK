//
//  DDCommandTask.m
//  healthCheck
//
//  Created by admin on 2019/10/24.
//  Copyright © 2019 xlf. All rights reserved.
//

#import "DDCommandTask.h"
#import "DDBlueIToll.h"
#import "DDHeartRateCheckRequest.h"

@interface DDCommandTask()

@property(nonatomic, weak) DDHeartRateCheckRequest *request;

@end

@implementation DDCommandTask

- (instancetype)initWithType:(DDBLECommandType)type request:(DDHeartRateCheckRequest *)request success:(DDCommandTaskSuccessBlock)success fail:(DDCommandTaskFailBlock)fail
{
    if (self = [super init]) {
        _successBlock = [success copy];
        _failBlock = [fail copy];
        _commandErrorRetryTimes = DDCommandTaskRetryTimes;
        _responseFailRetryTimes = DDCommandTaskRetryTimes;
        _duration = DDCommandTaskDuration;
        _request = request;
        _type = type;
    }
    return self;
}



+ (instancetype)createTaskWithType:(DDBLECommandType)type request:(DDHeartRateCheckRequest *)request success:(DDCommandTaskSuccessBlock)success fail:(DDCommandTaskFailBlock)fail
{
    DDCommandTask *task = [[DDCommandTask alloc] initWithType:type request:request success:success fail:fail];
    return task;
}

- (void)resume
{
    [self.request sendRequestWithTask:self];
}

/**
 通过CBPeripheral 类 将数据写入蓝牙外设中,蓝牙外设所识别的数据为十六进制数据,在ios系统代理方法中将十六进制数据改为 NSData 类型 ,但是该数据形式必须为十六进制数 0*ff 0*ff格式 在DDDBlueIToll中有将 字符串转化为 十六进制 再转化为 NSData的方法
 */
- (NSData *)encodeCommand
{
    NSData *data = nil;    
    switch (self.type) {
        case DDBLECommandTypeBindUserID: {
            unsigned char send[20] = {0xe8,0x41,0x33,0x44,0x55,0x55,0x66,0x77,0x88,0x99,0x11};
            data = [NSData dataWithBytes:send length:sizeof(send)];
        }
            break;
        case DDBLECommandTypeStartCollect:
            data = [self collectCommandData];
            break;
        case DDBLECommandTypeLiveECG: {
            unsigned char send[6] = {0xe8,0x20,0x01,0x36,0xEE,0x80};
            data = [NSData dataWithBytes:send length:sizeof(send)];
        }
            break;
        case DDBLECommandTypeTurnOffLiveECG: {
            unsigned char send[2] = {0xe8,0x26};
            data = [NSData dataWithBytes:send length:sizeof(send)];
        }
            break;
        case DDBLECommandTypeTurnOffCollect: {
            unsigned char send[2] = {0xe8,0x22};
            data = [NSData dataWithBytes:send length:sizeof(send)];
        }
            break;
        case DDBLECommandTypeSubscribeTime:
            data = [self timerServiceData];
            break;
        case DDBLECommandTypeQueryMachineDate:{
            unsigned char send[2] = {0xe8,0x1f};
            data = [NSData dataWithBytes:send length:sizeof(send)];
        }
            break;
        default: {//    DDBLECommandTypeQueryDeviceState,
            unsigned char send[2] = {0xe8,0x10};
            data = [NSData dataWithBytes:send length:sizeof(send)];
        }
            break;
    }
    return data;
}

//发送开始采集命令 采集是设备采集心电信号， 实时传输是设备进行数据传输
- (NSData *)collectCommandData
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yy-MM-dd-HH-mm-ss"];
    // 得到当前时间（世界标准时间 UTC/GMT）
    NSDate *nowDate = [NSDate date];
    NSString *nowDateString = [dateFormatter stringFromDate:nowDate];
    NSArray *dateArray = [nowDateString componentsSeparatedByString:@"-"];
    NSMutableArray *dateStrArray = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < dateArray.count; i++) {
        NSInteger time = [dateArray[i] integerValue];
        dateStrArray[i] = [DDBlueIToll getHexByDecimal:time];
    }
    NSString *dateStr = [dateStrArray componentsJoinedByString:@""];
    NSData *strDate = [DDBlueIToll hexToBytes:dateStr];
    // NSMutableArray *dataArr = [DDBlueIToll convertDataToHexStr:strDate];
    // 转Byte数组
    unsigned char *bytess = [self dataToByte:strDate];
    //发送绑定用户指令成功，开始放送开始采集命令
    unsigned char send[10] = {0xe8,0x23,0x29,0x06,0x1e,0x05,0x30,0x37,0xff,0xff};
    for (NSInteger i = 0; i < [strDate length]; i++) {
        send[i+2] = bytess[i];
    }
    
    NSData *data = [NSData dataWithBytes:send length:sizeof(send)];
    free(bytess);
    return data;
}

/// 发送装订时间
- (NSData *)timerServiceData{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yy-MM-dd-HH-mm-ss"];
    // 得到当前时间（世界标准时间 UTC/GMT）
    NSDate *nowDate = [NSDate date];
    NSString *nowDateString = [dateFormatter stringFromDate:nowDate];
    NSArray *dateArray = [nowDateString componentsSeparatedByString:@"-"];
    NSMutableArray *dateStrArray = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < dateArray.count; i++) {
        NSInteger time = [dateArray[i] integerValue];
        dateStrArray[i] = [DDBlueIToll getHexByDecimal:time];
    }
    NSString *dateStr = [dateStrArray componentsJoinedByString:@""];
    NSData *strDate = [DDBlueIToll hexToBytes:dateStr];
    // NSMutableArray *dataArr = [DDBlueIToll convertDataToHexStr:strDate];
    // 转Byte数组
    unsigned char *bytess = [self dataToByte:strDate];
    //发送链接成功就开始授时
    unsigned char send[8] = {0xe8,0x40,0x29,0x06,0x1e,0x05,0x30,0x37};
    for (NSInteger i = 0; i < [strDate length]; i++) {
        send[i+2] = bytess[i];
    }
    
    NSData *data = [NSData dataWithBytes:send length:sizeof(send)];
    free(bytess);
    return data;
}

- (Byte *)dataToByte:(NSData *)data
{
    NSUInteger len = [data length];
    Byte *byteData = (Byte*)malloc(len);
    memcpy(byteData, [data bytes], len);
    return byteData;
}

- (void)dealloc
{
    NSLog(@"dealloc:%@",self.description);
}

@end
