//
//  DDHeartRateCheckRequest.m
//  ElectrocardiographSDK
//
//  Created by tanshushu on 2020/11/11.
//

#import "DDHeartRateCheckRequest.h"
#import "DDBlueIToll.h"

#define DDRetrySendRequestDelay                2    //重试间隔时间

#define DDWeakObj(o) autoreleasepool{} __weak typeof(o) o##Weak = o;

#define DDStrongObj(o) autoreleasepool{} __strong typeof(o) o = o##Weak;
@interface DDHeartRateCheckRequest()<DDBlueClientDelegate>

@property (nonatomic, assign) NSInteger commondRetryTimes; //设备失败重试次数

@property (nonatomic, strong) DDBluetoothClient *bluetoothClient;

@property (nonatomic, strong) DDCommandTask *currentTask;
@property (nonatomic, strong) dispatch_source_t timer;
@end
@implementation DDHeartRateCheckRequest
- (instancetype)init
{
    self = [super init];
    if (self) {
        _commondRetryTimes = DDCommondRetryTimes;
    }
    return self;
}
#pragma mark 内部自定义方法
/// 一切初始化
-(void)clearAllLastState{
   
}
- (NSString *)hexStringWithData:(NSData *)data
{
    Byte *bytes = (Byte *)data.bytes;
    NSString * bytStr = @"";
    for (int i = 0; i < data.length; i++) {
        Byte byte = bytes[i]&0xff;
        bytStr = [bytStr stringByAppendingFormat:@"%02x",byte];
    }
    return bytStr;
}
- (DDBLECommandType)transfromCommandType:(NSString *)bytStr
{
    DDBLECommandType command = DDBLECommandTypeUnknown;
    if ([bytStr hasPrefix:DDECGCommandError]) {
        command = DDBLECommandTypeError;
    } else if ([bytStr hasPrefix:DDECGCommandQueryState]) {
        command = DDBLECommandTypeQueryState;
    } else if ([bytStr hasPrefix:DDECGCommandLiveECG]) {
        command = DDBLECommandTypeLiveECG;
    } else if ([bytStr hasPrefix:DDECGCommandTurnOffCollect]) {
        command = DDBLECommandTypeTurnOffCollect;
    } else if ([bytStr hasPrefix:DDECGCommandStartCollect]) {
        command = DDBLECommandTypeStartCollect;
    } else if ([bytStr hasPrefix:DDECGCommandBindUserId]) {
        command = DDBLECommandTypeBindUserID;
    } else if ([bytStr hasPrefix:DDECGCommandResponseLiveECG]) {
        command = DDBLECommandTypeResponseLiveECG;
    }else if ([bytStr hasPrefix:DDECGCommandSubscribeTime])
    {
        command = DDBLECommandTypeSubscribeTime;
    }
    else {
        //其余命令没有使用就不做处理
    }
    
    return command;
}

- (void)closeBlutoothConnect:(BOOL )signOut
{
    if (self.currentTask && self.currentTask.type == DDBLECommandTypeTurnOffCollect) {
        [self performSelector:@selector(closeBlutoothConnect:) withObject:nil afterDelay:0.5];
    } else {
        [self.bluetoothClient disconnect:signOut];
    }
}
//停止扫描设备
- (void)stopScan{
    [self.bluetoothClient stopScan];
}
- (void)dealloc
{
    NSLog(@"dealloc:%@",self.description);
}

#pragma mark - handle reviced data
- (void)hanldeRevicedData:(NSData *)data{
    NSLog(@"%@",data);
    NSString *bytStr = [self hexStringWithData:data];
    DDBLECommandType commandType = [self transfromCommandType:bytStr];
    DDCommandTask *task = self.currentTask;
    if (commandType == DDBLECommandTypeResponseLiveECG) {
        if (task) {
            self.currentTask = nil;
            if (task.type == DDBLECommandTypeLiveECG) {//实时的心电数据
                if (task.successBlock) {
                    task.successBlock(YES, @"");
                }
            }else{
                //注意：这个逻辑可能有问题，因为在接收数据的时候发送的指令可能会干扰被自动错误
                if (task.failBlock) {
                    task.failBlock(DDCommandTaskErrorTypeAutoStopTaskError, @"出现异常采集"); //如果当前指令不是开始实时采集，出现了实时采集，正常情况不会出现，如果出现进入开始采集状态
                }
                [DDBlueIToll DDLog:@"---blue---出现异常情况，当前指令不是实时采集，缺出现实时采集数据"];
            }
        }
        if ([self.delegate respondsToSelector:@selector(didReceiveLiveECGData:byteStr:byteData:)]) {
            [self.delegate didReceiveLiveECGData:self byteStr:bytStr byteData:data];
        }
    }else if(commandType == DDBLECommandTypeError){//错误命令包含0xE8 0xFF 00000000 和0xE8 + 命令     000000000
        if (task) {
            if (task.commandErrorRetryTimes > 0) {
                [self performSelector:@selector(retrySendRequestWhenCommandErrorWithTask) withObject:nil afterDelay:DDRetrySendRequestDelay];
            }else{
                [self cancelTimer];
                self.currentTask = nil;
                if (task.failBlock) {
                    task.failBlock(DDCommandTaskErrorTypeCommandError, @"设备返回08FF00000000");
                }
            }
           
        }
    }else{//非实时传输的心电数据
        [self hanldeRequestResult:commandType byteStr:bytStr];
    }
}
//处理数据
- (void)hanldeRequestResult:(DDBLECommandType)type byteStr:(NSString *)byteStr
{
    DDCommandTask *task = self.currentTask;
    if (task) {
        if (task.type == type) {
            BOOL isSuccess = YES;
            if (task.type != DDBLECommandTypeQueryState) {//不是/查询设备状态
                NSString *last = [byteStr substringFromIndex:byteStr.length-1];
                isSuccess = [last boolValue];//返回了失败就去在查询
                if (!isSuccess) {
                    if (task.responseFailRetryTimes > 0) {
                        [self performSelector:@selector(retrySendRequestWhenResponseFailWithTask) withObject:nil afterDelay:DDRetrySendRequestDelay];
                        return;
                    }
                }
            }
            [self cancelTimer];
            self.currentTask = nil;
            if (task.successBlock) {
                task.successBlock(isSuccess, byteStr);
            }
        }else{
            [DDBlueIToll DDLog:@"---blue---设备指令异常，返回了与正在执行的指令不一致的指令"];
        }
    }else{
        [DDBlueIToll DDLog:@"---blue---设备指令异常，当前没有正在执行，却返回了的指令"];
    }
}
- (void)retrySendRequestWhenCommandErrorWithTask
{
    //只所以retry重新添加，y是因为可能延时逻辑和检测超时逻辑冲突，retry之前都进行移除
    if (self.currentTask.commandErrorRetryTimes > 0) {
        self.currentTask.commandErrorRetryTimes--;
        self.currentTask.responseFailRetryTimes = DDCommondRetryTimes;
        [self.bluetoothClient sendData:[self.currentTask encodeCommand]];
    }
}
- (void)retrySendRequestWhenResponseFailWithTask
{
    //只所以retry重新添加，y是因为可能延时逻辑和检测超时逻辑冲突，retry之前都进行移除
    if (self.currentTask.responseFailRetryTimes > 0) {
        self.currentTask.responseFailRetryTimes--;
        self.currentTask.commandErrorRetryTimes = DDCommondRetryTimes;
        [self.bluetoothClient sendData:[self.currentTask encodeCommand]];
    }
}

- (void)startTimer
{
    if (self.timer == nil) {
        @DDWeakObj(self);
        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(_timer, dispatch_walltime(NULL, 0), 1 * NSEC_PER_SEC, 0); //每秒执行
        dispatch_source_set_event_handler(_timer, ^{
            @DDStrongObj(self);
            DDCommandTask *task = self.currentTask;
            if (task) {
                task.duration--;
                if (task.duration <=0 ) {
                    [NSObject cancelPreviousPerformRequestsWithTarget:self];//取消所有延时处理
//                    self.isCheckStop = YES;
                    self.currentTask = nil;
                    if (task.failBlock) {
                        task.failBlock(DDCommandTaskErrorTypeTimeOut, @"task time out");
                    }
                }
            } else {
                [self cancelTimer];
            }
        });
        dispatch_resume(_timer);
    }
}

- (void)cancelTimer
{
    if (self.timer) {
        dispatch_cancel(self.timer);
    }
    self.timer = nil;
}

/// 失败
- (void)handleTaskWhenBluetoothError
{
    
    if (self.currentTask.failBlock) {
        self.currentTask.failBlock(DDCommandTaskErrorTypeBluetoothError, @"bluetooth error");
    }
    [self cancelTimer];
    [self clearAllLastState];
}
#pragma mark 暴露给外面调用的自定义方法
/// 开始扫描
- (void)startCheck{
    [self clearAllLastState];
    _bluetoothClient = [[DDBluetoothClient alloc]init];
    _bluetoothClient.bluetoothServiceUUID =  DDMachineBlueServiceUUID;
    _bluetoothClient.delegate = self;
    [self.bluetoothClient startRunning];
}

/// 选择设备
/// @param peripheral 选择的那个
/// @param advertisementData 数据
-(void)chooseDevicePeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString*,id> *)advertisementData{
    NSData *data = [advertisementData objectForKey:@"kCBAdvDataManufacturerData"];
    if (data.length == 10) {
        _bluetoothClient.bluetoothDeviceName =  DDMachineBlue5Name;
        _bluetoothClient.characteristicReadUUID = DDBlue5CharacteristicsRead;
        _bluetoothClient.characteristicWriteUUID = DDBlue5CharacteristicsSend;
    }else{
        _bluetoothClient.bluetoothDeviceName = DDMachineBlue4Name;
        _bluetoothClient.characteristicReadUUID = DDBlue4CharacteristicsRead;
        _bluetoothClient.characteristicWriteUUID = DDBlue4CharacteristicsSend;
    }
    //连接蓝牙
    [_bluetoothClient startConnectPeripheral:peripheral];
}

/// 做任务
/// @param task 任务模型
- (void)sendRequestWithTask:(DDCommandTask *)task{
    
    
    self.currentTask = task;
    [self.bluetoothClient sendData:[task encodeCommand]];
    [self startTimer];
    
    
}

#pragma 代理
/// 扫描广播
/// @param request ——
/// @param peripheral ——
/// @param advertisementData ——
/// @param RSSI ——
- (void)isTargetDevice:(DDHeartRateCheckRequest * )request
                peripheral:(CBPeripheral *)peripheral
         advertisementData:(NSDictionary<NSString *,id> *)advertisementData
                  RSSI:(NSNumber *)RSSI{
   
    if ([self.delegate respondsToSelector:@selector(isTargetDevice:peripheral:advertisementData:RSSI:)]) {
        [self.delegate isTargetDevice:self peripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
    }
}

/// 没有搜索到设备
/// @param request ——
- (void)didScanDeviceFail:(DDHeartRateCheckRequest * )request{
    if ([self.delegate respondsToSelector:@selector(didScanDeviceFail:)]) {
        [self.delegate didScanDeviceFail:self];
    }
}

/// 找到了设备
/// @param request ——
- (void)didDiscoverDevice:(DDHeartRateCheckRequest * )request{
    if ([self.delegate respondsToSelector:@selector(didDiscoverDevice:)]) {
        [self.delegate didDiscoverDevice:self];
    }
}

/// 连接成功
/// @param request - -
- (void)didConnectDevice:(DDHeartRateCheckRequest * )request{
    if ([self.delegate respondsToSelector:@selector(didConnectDevice:)]) {
        [self.delegate didConnectDevice:self];
    }
}

/// 连接设备失败
/// @param request ——
- (void)didConnectDeviceFail:(DDHeartRateCheckRequest * )request{
    [self handleTaskWhenBluetoothError];
    if ([self.delegate respondsToSelector:@selector(didConnectDeviceFail:)]) {
        [self.delegate didConnectDeviceFail:self];
    }
}

/// 设备断开
/// @param request ——
- (void)didDisconnectDevice:(DDHeartRateCheckRequest * )request{
    if ([self.delegate respondsToSelector:@selector(didDisconnectDevice:)]) {
        [self.delegate didDisconnectDevice:self];
    }
}

/// 找到目标服务
/// @param request ——
- (void)didDiscoverService:(DDHeartRateCheckRequest * )request{
    if ([self.delegate respondsToSelector:@selector(didDiscoverService:)]) {
        [self.delegate didDiscoverService:self];
    }
}

/// 已经连接 并且已经找到读写服务
/// @param request ——
- (void)didCompleteServicePrepare:(DDHeartRateCheckRequest * )request{
    if ([self.delegate respondsToSelector:@selector(didCompleteServicePrepare:)]) {
        [self.delegate didCompleteServicePrepare:self];
    }
}

/// 接收数据
/// @param request ——
/// @param data 数据
- (void)didReceiveData:(DDHeartRateCheckRequest * )request data:(NSData *)data{
    [self hanldeRevicedData:data];
    if ([self.delegate respondsToSelector:@selector(didReceiveData:data:)]) {
        [self.delegate didReceiveData:self data:data];
    }
}

/// 写入数据
/// @param request ——
/// @param error 失败原因
- (void)didWriteData:(DDHeartRateCheckRequest * )request error:(NSError *)error{
    if ([self.delegate respondsToSelector:@selector(didWriteData:error:)]) {
        [self.delegate didWriteData:self error:error];
    }
}

/// 蓝牙的状态
/// @param request ——
/// @param state 状态
- (void)clientDidUpdateState:(DDHeartRateCheckRequest * )request state:(CBManagerState)state{
    if ([self.delegate respondsToSelector:@selector(clientDidUpdateState:state:)]) {
        [self.delegate clientDidUpdateState:self state:state];
    }
}

//数据通知错误被停止
- (void)readDataFail:(DDHeartRateCheckRequest * )request error:(NSError *)error{
    if ([self.delegate respondsToSelector:@selector(readDataFail:error:)]) {
        [self.delegate readDataFail:self error:error];
    }
}

@end
