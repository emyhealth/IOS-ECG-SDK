//
//  DDHeartRateCheckManager.m
//  ElectrocardiographSDK
//
//  Created by tanshushu on 2020/11/12.
//

#import "DDHeartRateCheckManager.h"
#import "DDHeartRateCheckRequest.h"
#import "DDCommandTask.h"
#import "DDBlueIToll.h"
#import "ElectrocardiographSDK.h"
#define kDDCheckECGDataExceptionLocalError      -95004 //ecg数据长度不足4分50秒
#define DDWeakObj(o) autoreleasepool{} __weak typeof(o) o##Weak = o;
#define DDStrongObj(o) autoreleasepool{} __strong typeof(o) o = o##Weak;


@interface DDHeartRateCheckManager()<DDBlueRequestManagerDelegate>
@property (nonatomic, strong) NSMutableData *ecgData; //ECG 数据 原始数据
@property (nonatomic, assign) CGFloat lastResult; //最后的高通数据 默认-1001
@property (nonatomic, strong) NSMutableArray *preValueArray; //高通计算需要的数据

/// 是否需要自动处理
@property(nonatomic,assign)BOOL automaticCopy;
/// 请求类
@property (nonatomic, strong) DDHeartRateCheckRequest *checkRequest;

/// 当前执行的状态
@property (nonatomic, assign) DDFlowState currentFlowState;

/// 5.0以下的设备为YES
@property(nonatomic,assign)BOOL XinDianTiePortable;
@end

static DDHeartRateCheckManager *instance = nil;
@implementation DDHeartRateCheckManager

+ (instancetype)shared
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[DDHeartRateCheckManager alloc]init];
    });
    return instance;
}
#pragma mark --- 自定义事件

/// 连接成功
-(void)queryDeviceStatus{
    [self timerServiceAction];
}
/// 去装订时间
- (void)timerServiceAction{
    @DDWeakObj(self);
    [DDBlueIToll DDLog:@"---blue---装订时间"];
    [[DDCommandTask createTaskWithType:DDBLECommandTypeSubscribeTime request:self.checkRequest success:^(BOOL success, NSString * _Nonnull byteStr) {
        [DDBlueIToll DDLog:@"---blue---装订时间成功"];
        @DDStrongObj(self);
        [self queryDeviceStatusCopy];
    } fail:^(DDCommandTaskErrorType errType, NSString * _Nonnull errorInfo) {
        [DDBlueIToll DDLog:@"---blue---装订时间失败"];
        @DDStrongObj(self);
        [self handleRequestFail:errType errorMsg:errorInfo];
    }] resume];
}
//查询设备状态
- (void)queryDeviceStatusCopy{
    [DDBlueIToll DDLog:@"---blue---查询设备状态"];
    @DDWeakObj(self);
    [[DDCommandTask createTaskWithType:DDBLECommandTypeQueryState request:self.checkRequest success:^(BOOL success, NSString * _Nonnull byteStr) {
        [DDBlueIToll DDLog:@"---blue---查询设备成功"];
        @DDStrongObj(self);
        [self handleQueryResult:byteStr];
    } fail:^(DDCommandTaskErrorType errType, NSString * _Nonnull errorInfo) {
        @DDStrongObj(self);
        [self handleRequestFail:errType errorMsg:errorInfo];
    }] resume];
    
}

//绑定用户命令
- (void)startBindUid
{
    
    [DDBlueIToll DDLog:@"---blue---开始绑定"];
    self.currentFlowState = DDFlowStateBind;
    @DDWeakObj(self);
    
    [[DDCommandTask createTaskWithType:DDBLECommandTypeBindUserID request:self.checkRequest success:^(BOOL success, NSString *byteStr) {
        [DDBlueIToll DDLog:@"---blue---绑定成功"];
        @DDStrongObj(self);
        if (success) {
            if (self.stateBlock) {
                self.stateBlock(DDHeartRateCheckStateBindSuccess);
            }
            [self startCollectECG];
        } else {
            
            [self queryDeviceStatusCopy];
        }
    } fail:^(DDCommandTaskErrorType errType, NSString * _Nonnull errorInfo) {
        [DDBlueIToll DDLog:@"---blue---绑定失败"];
        @DDStrongObj(self);
        [self handleRequestFail:errType errorMsg:errorInfo];
    }] resume];
}

//发送开始采集命令 采集是设备采集心电信号， 实时传输是设备进行数据传输
- (void)startCollectECG
{
    [DDBlueIToll DDLog:@"---blue---发送开始采集命令"];
    self.currentFlowState = DDFlowStateCollect;
    @DDWeakObj(self);
    [[DDCommandTask createTaskWithType:DDBLECommandTypeStartCollect request:self.checkRequest success:^(BOOL success, NSString *byteStr) {
        [DDBlueIToll DDLog:@"---blue---发送开始采集命令成功"];
        @DDStrongObj(self);
        if (success) {
            if (self.stateBlock) {
                self.stateBlock(DDHeartRateCheckStateCollectSuccess);
            }
            [self startLiveECGData];
        } else {
           
     //5.0需要处理当前失败原因,需要添加逻辑
            [self queryDeviceStatusCopy];
        }
    } fail:^(DDCommandTaskErrorType errType, NSString * _Nonnull errorInfo) {
        [DDBlueIToll DDLog:@"---blue---发送开始采集命令失败"];
        @DDStrongObj(self);
        [self handleRequestFail:errType errorMsg:errorInfo];
    }] resume];
}

//实时传输命令
- (void)startLiveECGData
{

    [DDBlueIToll DDLog:@"---blue---实时传输命令"];
    self.currentFlowState = DDFlowStateLiveECG;
    @DDWeakObj(self);
    [[DDCommandTask createTaskWithType:DDBLECommandTypeLiveECG request:self.checkRequest success:^(BOOL success, NSString * _Nonnull byteStr) {
        [DDBlueIToll DDLog:@"---blue---实时传输命令成功"];
        //实时传输没有reponse的,底层对回调数据为ECG数据表示成功
        @DDStrongObj(self);
        if (self.stateBlock) {
            self.stateBlock(DDHeartRateCheckStateStartLiveECGSuccess);
        }
    } fail:^(DDCommandTaskErrorType errType, NSString * _Nonnull errorInfo) {
        [DDBlueIToll DDLog:@"---blue---实时传输命令失败"];
        @DDStrongObj(self);
        [self handleRequestFail:errType errorMsg:errorInfo];
    }] resume];
}
// 结束单机采集
- (void)stopCollectECG
{
    [DDBlueIToll DDLog:@"---blue---结束单机采集命令"];
    @DDWeakObj(self);
    [[DDCommandTask createTaskWithType:DDBLECommandTypeTurnOffCollect request:self.checkRequest success:^(BOOL success, NSString * _Nonnull byteStr) {
        [DDBlueIToll DDLog:@"---blue---结束单机采集命令成功"];
        @DDStrongObj(self);
        if (success) {
            if (self.stateBlock) {
                self.stateBlock(DDHeartRateCheckStateStopCollectSuccess);
            }
        }else{
            if (self.stateBlock) {
                self.stateBlock(DDHeartRateCheckStateStopCollectFail);
            }
        }
    } fail:^(DDCommandTaskErrorType errType, NSString * _Nonnull errorInfo) {
       
        //结束采集了不做处理, 回调还是返回
        @DDStrongObj(self);
        if (self.stateBlock) {
            self.stateBlock(DDHeartRateCheckStateStopCollectFail);
        }
    }] resume];
}

//设备待机
- (void)continueWhenDeviceAwait
{
    switch (self.currentFlowState) {
        case DDFlowStateBind: {
            [self startBindUid];
        }
            break;
        case DDFlowStateLiveECG: {
            [self startCollectECG];
        }
            break;
       
            break;
            
        default:
            break;
    }
}
//设备在采集中
- (void)continueWhenDeviceCollecting
{
    @DDWeakObj(self);
    //当前实时采集是不会有查询状态的，所以这里全部做停止实时采集
    void(^successBlock)(void) = ^{
        @DDStrongObj(self);
        switch (self.currentFlowState) {
            case DDFlowStateBind:
            case DDFlowStateCollect:
            case DDFlowStateLiveECG: {
                [self startBindUid];//这里关闭采集之后需要重新走bind逻辑
            }
                break;
            case DDFlowStateTurnOffCollect: {
//                if (self.stateBlock) {
//                    self.stateBlock(DDHeartRateCheckStateExceptionFinish);
//                }
//                [self.checkRequest enterCloseCheckState];
                self.currentFlowState = DDFlowStateWait; //流程结束应该重置当前的状态或者
            }
                break;
                
            default:
                break;
        }
    };
    
    [self turnoffCollectForQueryDeviceStatus:NO success:^(BOOL success, NSString *byteStr) {
        if (success) {
            successBlock();
        }
    }];
}
- (void)turnoffCollectForQueryDeviceStatus:(BOOL)isRetry success:(void(^)(BOOL success, NSString * byteStr))successBlock
{
    @DDWeakObj(self);
    
    [[DDCommandTask createTaskWithType:DDBLECommandTypeTurnOffCollect request:self.checkRequest success:^(BOOL success, NSString * _Nonnull byteStr) {
        @DDStrongObj(self);
        if (success) {
          
            if (successBlock) {
                successBlock(success, byteStr);
            }
        } else {
            
            if (isRetry) {
//                [self.checkRequest enterCloseCheckState];
                if (self.currentFlowState != DDFlowStateTurnOffCollect) {
                    if (self.stateBlock) {
                        self.stateBlock(DDHeartRateCheckStateExceptionFinish);
                    }
                }
                self.currentFlowState = DDFlowStateWait;
            } else {
                //如果是第一次多做一次重试
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self turnoffCollectForQueryDeviceStatus:YES success:successBlock];//重试
                });
            }
        }
    } fail:^(DDCommandTaskErrorType errType, NSString * _Nonnull errorInfo) {
        //结束采集了不做处理
        @DDStrongObj(self);
        [self handleRequestFail:errType errorMsg:errorInfo];
    }] resume];
}
- (void)handleRequestFail:(DDCommandTaskErrorType)errType errorMsg:(NSString * _Nonnull)errorInfo
{
    if (self.currentFlowState == DDFlowStateBind || self.currentFlowState == DDFlowStateCollect || self.currentFlowState == DDFlowStateLiveECG) {
        switch (errType) {
            case DDCommandTaskErrorTypeTimeOut: {

                if (self.stateBlock) {
                    self.stateBlock(DDHeartRateCheckStateCommandSendTimeout);
                }
            }
                break;
            case DDCommandTaskErrorTypeCommandError: {
               
                if (self.stateBlock) {
                    self.stateBlock(DDHeartRateCheckStateServiceError);
                }
            }
                break;
                
            default:
                break;
        }
    }
    self.currentFlowState = DDFlowStateWait; //流程结束应该重置当前的状态或者
}

#pragma  mark --- 初始化
- (instancetype)init
{
    if (self = [super init]) {
        _automaticCopy = NO;
        _currentFlowState = DDFlowStateWait;
//        _commondRetryTimes = DDCommondRetryTimes;
        _ecgData = [[NSMutableData alloc] init];
        _preValueArray = [[NSMutableArray alloc] init];
        _lastResult = -1001.0;//给默认无效值
    }
    return self;
}

#pragma mark --- 暴露给外部的API
/// 开始扫描
- (void)startCheckAutomatic:(BOOL)automatic{
    _automaticCopy = automatic;
    [self clearAllLastState];
    if (!_checkRequest) {
        _checkRequest = [[DDHeartRateCheckRequest alloc]init];
        _checkRequest.delegate = self;
    }
    [self.checkRequest startCheck];
}

/// 选择一台设备信息连接
/// @param peripheral 代理里面传递的
/// @param advertisementData 代理里面传递的
-(void)chooseDevicePeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString*,id> *)advertisementData{
    NSData *data = [advertisementData objectForKey:@"kCBAdvDataManufacturerData"];
    if (data.length == 10) {
        _XinDianTiePortable = NO;
    }else{
        _XinDianTiePortable = YES;
    }
    [self.checkRequest chooseDevicePeripheral:peripheral advertisementData:advertisementData];
}

/// 停止一切操作 包括：停止蓝牙扫描，蓝牙连接，蓝牙广播回调、设备停止采集
- (void)endCheck:(BOOL )signOut{
    if (self.stateBlock) {
        self.stateBlock(DDHeartRateCheckStateStopCollect);
    }
    self.currentFlowState = DDFlowStateTurnOffCollect;
    [self.checkRequest closeBlutoothConnect:signOut];
    [self stopCollectECG];
}
//停止扫描设备
- (void)stopScan{
    [self.checkRequest stopScan];
}

/// 该方法用于查询心电记录仪的设备状态，包括：电压值、设备运行状态（采集、待机）
/// @param successRequest 成功返回数据
/// @param failRequest 失败
-(void)queryDeviceStatusSuccess:(void (^)(BOOL success, NSString *byteStr))successRequest fail:(void (^)(DDCommandTaskErrorType errType,NSString *errrorInfo))failRequest{
    
    [[DDCommandTask createTaskWithType:DDBLECommandTypeQueryState request:self.checkRequest success:^(BOOL success_, NSString * _Nonnull byteStr_) {
        successRequest(success_,byteStr_);
        } fail:^(DDCommandTaskErrorType errType_, NSString * _Nonnull errorInfo_) {
            failRequest(errType_,errorInfo_);
        }] resume];
    
}

/// 该方法用于返回心电记录仪的设备型号。
/// @param successRequest 成功返回数据
/// @param failRequest 失败
-(void)queryDeviceModelSuccess:(void (^)(BOOL success, NSString *byteStr))successRequest fail:(void (^)(DDCommandTaskErrorType errType,NSString *errrorInfo))failRequest{
    [[DDCommandTask createTaskWithType:DDBLECommandTypeQueryMachineModel request:self.checkRequest success:^(BOOL success_, NSString * _Nonnull byteStr_) {
        successRequest(success_,byteStr_);
        } fail:^(DDCommandTaskErrorType errType_, NSString * _Nonnull errorInfo_) {
            failRequest(errType_,errorInfo_);
        }] resume];
}

/// 该方法用于返回心电记录仪的设备时间。
/// @param successRequest 成功返回数据
/// @param failRequest 失败
-(void)queryDeviceTimerSuccess:(void (^)(BOOL success, NSString *byteStr))successRequest fail:(void (^)(DDCommandTaskErrorType errType,NSString *errrorInfo))failRequest{
    [[DDCommandTask createTaskWithType:DDBLECommandTypeQueryMachineDate request:self.checkRequest success:^(BOOL success_, NSString * _Nonnull byteStr_) {
        successRequest(success_,byteStr_);
        } fail:^(DDCommandTaskErrorType errType_, NSString * _Nonnull errorInfo_) {
            failRequest(errType_,errorInfo_);
        }] resume];
}

/// 该方法用于向心电记录仪绑定用户信息，设备用户id与该次检测的关联关系。返回成功或者失败
/// @param successRequest 成功返回数据
/// @param failRequest 失败
-(void)bindUserIdSuccess:(void (^)(BOOL success, NSString *byteStr))successRequest fail:(void (^)(DDCommandTaskErrorType errType,NSString *errrorInfo))failRequest{
    self.currentFlowState = DDFlowStateBind;
    [[DDCommandTask createTaskWithType:DDBLECommandTypeBindUserID request:self.checkRequest success:^(BOOL success_, NSString * _Nonnull byteStr_) {
        successRequest(success_,byteStr_);
        } fail:^(DDCommandTaskErrorType errType_, NSString * _Nonnull errorInfo_) {
            failRequest(errType_,errorInfo_);
        }] resume];
    
}
/// 该方法用于向心电记录仪装订时间，用于纠正心电记录仪时钟的时间。返回成功或者失败；
/// @param successRequest 成功返回数据
/// @param failRequest 失败
-(void)subscribeTimeSuccess:(void (^)(BOOL success, NSString *byteStr))successRequest fail:(void (^)(DDCommandTaskErrorType errType,NSString *errrorInfo))failRequest{
    [[DDCommandTask createTaskWithType:DDBLECommandTypeSubscribeTime request:self.checkRequest success:^(BOOL success_, NSString * _Nonnull byteStr_) {
        successRequest(success_,byteStr_);
        } fail:^(DDCommandTaskErrorType errType_, NSString * _Nonnull errorInfo_) {
            failRequest(errType_,errorInfo_);
        }] resume];
}
/// 该方法用于向心电记录仪发送开始采集的指令，返回成功或者失败。失败的原因（存储空间不足，电量不足，其他）
/// @param successRequest 成功返回数据
/// @param failRequest 失败
-(void)StartCollectSuccess:(void (^)(BOOL success, NSString *byteStr))successRequest fail:(void (^)(DDCommandTaskErrorType errType,NSString *errrorInfo))failRequest{
    self.currentFlowState = DDFlowStateCollect;
    [[DDCommandTask createTaskWithType:DDBLECommandTypeStartCollect request:self.checkRequest success:^(BOOL success_, NSString * _Nonnull byteStr_) {
        successRequest(success_,byteStr_);
        } fail:^(DDCommandTaskErrorType errType_, NSString * _Nonnull errorInfo_) {
            failRequest(errType_,errorInfo_);
        }] resume];
}
/// 该方法用于向心电记录仪发送实时传输采集的指令，返回成功或者失败
/// @param successRequest 成功返回数据
/// @param failRequest 失败
-(void)typeLiveECGSuccess:(void (^)(BOOL success, NSString *byteStr))successRequest fail:(void (^)(DDCommandTaskErrorType errType,NSString *errrorInfo))failRequest{
    self.currentFlowState = DDFlowStateLiveECG;
    [[DDCommandTask createTaskWithType:DDBLECommandTypeLiveECG request:self.checkRequest success:^(BOOL success_, NSString * _Nonnull byteStr_) {
        successRequest(success_,byteStr_);
        } fail:^(DDCommandTaskErrorType errType_, NSString * _Nonnull errorInfo_) {
            failRequest(errType_,errorInfo_);
        }] resume];
}
/// 该方法用于向心电记录仪发送停止实时传输的指令。返回成功或者失败
/// @param successRequest 成功返回数据
/// @param failRequest 失败
-(void)TurnOffLiveECGSuccess:(void (^)(BOOL success, NSString *byteStr))successRequest fail:(void (^)(DDCommandTaskErrorType errType,NSString *errrorInfo))failRequest{
    [[DDCommandTask createTaskWithType:DDBLECommandTypeTurnOffLiveECG request:self.checkRequest success:^(BOOL success_, NSString * _Nonnull byteStr_) {
        successRequest(success_,byteStr_);
        } fail:^(DDCommandTaskErrorType errType_, NSString * _Nonnull errorInfo_) {
            failRequest(errType_,errorInfo_);
        }] resume];
}


/// 该方式用于向心电记录仪发送结束采集的指令，返回成功或者失败
/// @param successRequest 成功返回数据
/// @param failRequest 失败
-(void)turnOffCollectSuccess:(void (^)(BOOL success, NSString *byteStr))successRequest fail:(void (^)(DDCommandTaskErrorType errType,NSString *errrorInfo))failRequest{
    self.currentFlowState = DDFlowStateTurnOffCollect;
    [[DDCommandTask createTaskWithType:DDBLECommandTypeTurnOffCollect request:self.checkRequest success:^(BOOL success_, NSString * _Nonnull byteStr_) {
        successRequest(success_,byteStr_);
        } fail:^(DDCommandTaskErrorType errType_, NSString * _Nonnull errorInfo_) {
            failRequest(errType_,errorInfo_);
        }] resume];
}
/// 向心电记录仪发送数据
/// @param type 数据类型
/// @param successRequest 成功
/// @param failRequest 失败
-(void)turnOffCollect:(DDBLECommandType)type Success:(void (^)(BOOL success, NSString *byteStr))successRequest fail:(void (^)(DDCommandTaskErrorType errType,NSString *errrorInfo))failRequest{
    [[DDCommandTask createTaskWithType:type request:self.checkRequest success:^(BOOL success_, NSString * _Nonnull byteStr_) {
        successRequest(success_,byteStr_);
        } fail:^(DDCommandTaskErrorType errType_, NSString * _Nonnull errorInfo_) {
            failRequest(errType_,errorInfo_);
        }] resume];
}
#pragma mark ------ 处理查询设备状态结果

- (void)handleQueryResult:(NSString *)byteStr
{
    // 0x03：单机采集        0x02：同步采集        0x01：实时采集       0x00：待机
    if (byteStr.length < 12) {
        return;
    }
    NSString *status_B = [byteStr substringWithRange:NSMakeRange(7,1)];
    NSString *status_X = [byteStr substringWithRange:NSMakeRange(8,2)];
    NSString *status_Y = [byteStr substringWithRange:NSMakeRange(10,2)];

    [self computeElectricity:status_X yStr:status_Y];
    
    NSInteger status = [status_B integerValue];//第八位，第78位表示状态目前只有3状态所以支取最后一位够用
    switch (status) {
        case DDDeviceStateAwait:
            [self continueWhenDeviceAwait];
            break;
        case DDDeviceStateOfflineCollect:
            [self continueWhenDeviceCollecting];
            break;
            
        default:
            [DDBlueIToll DDLog:@"---blue--设备状态异常"];
            break;
    }
}

//electricityBlock
- (void)computeElectricity:(NSString *)xStr yStr:(NSString *)yStr
{
    
    NSInteger x = strtoul(xStr.UTF8String, 0, 16);
    NSInteger y = strtoul(yStr.UTF8String, 0, 16);
    CGFloat result = (x * 256 + y)/10000.00;
    CGFloat electricity = 0.0;
    if (_XinDianTiePortable) {
        //4.3
        if (result >= 4.16) {
            electricity = 1.0;
        } else if (result >= 4.15 && result < 4.16) {
            electricity = 0.99;
        } else if (result >= 4.14 && result < 4.15) {
            electricity = 0.97;
        } else if (result >= 4.12 && result < 4.14) {
            electricity = 0.95;
        } else if (result >= 4.10 && result < 4.12) {
            electricity = 0.92;
        } else if (result >= 4.08 && result < 4.10) {
            electricity = 0.90;
        } else if (result >= 4.05 && result < 4.08) {
            electricity = 0.87;
        } else if (result >= 4.03 && result < 4.05) {
            electricity = 0.85;
        } else if (result >= 3.97 && result < 4.03) {
            electricity = 0.80;
        } else if (result >= 3.93 && result < 3.97) {
            electricity = 0.75;
        } else if (result >= 3.90 && result < 3.93) {
            electricity = 0.70;
        } else if (result >= 3.87 && result < 3.90) {
            electricity = 0.65;
        } else if (result >= 3.84 && result < 3.87) {
            electricity = 0.60;
        } else if (result >= 3.81 && result < 3.84) {
            electricity = 0.55;
        } else if (result >= 3.79 && result < 3.81) {
            electricity = 0.50;
        } else if (result >= 3.77 && result < 3.79) {
            electricity = 0.45;
        } else if (result >= 3.76 && result < 3.77) {
            electricity = 0.40;
        } else if (result >= 3.74 && result < 3.76) {
            electricity = 0.35;
        } else if (result >= 3.73 && result < 3.74) {
            electricity = 0.30;
        } else if (result >= 3.72 && result < 3.73) {
            electricity = 0.25;
        } else if (result >= 3.71 && result < 3.72) {
            electricity = 0.20;
        } else if (result >= 3.69 && result < 3.71) {
            electricity = 0.15;
        } else if (result >= 3.66 && result < 3.69) {
            electricity = 0.12;
        } else if (result >= 3.65 && result < 3.66) {
            electricity = 0.10;
        } else if (result >= 3.64 && result < 3.65) {
            electricity = 0.08;
        } else if (result >= 3.63 && result < 3.64) {
            electricity = 0.05;
        } else if (result >= 3.61 && result < 3.63) {
            electricity = 0.03;
        } else if (result >= 3.59 && result < 3.61) {
            electricity = 0.01;
        } else if (result >= 3.58 && result < 3.59) {
            electricity = 0.0;
        }
    } else {
        //5.0
        if (result >= 4.125) {
            electricity = 1.0;
        } else if (result >= 4.075 && result < 4.125) {
            electricity = 0.95;
        } else if (result >= 4.031 && result < 4.075) {
            electricity = 0.90;
        } else if (result >= 3.991 && result < 4.031) {
            electricity = 0.85;
        } else if (result >= 3.955 && result < 3.991) {
            electricity = 0.80;
        } else if (result >= 3.922 && result < 3.955) {
            electricity = 0.75;
        } else if (result >= 3.890 && result < 3.922) {
            electricity = 0.70;
        } else if (result >= 3.858 && result < 3.890) {
            electricity = 0.65;
        } else if (result >= 3.819 && result < 3.858) {
            electricity = 0.60;
        } else if (result >= 3.793 && result < 3.819) {
            electricity = 0.55;
        } else if (result >= 3.775 && result < 3.793) {
            electricity = 0.50;
        } else if (result >= 3.761 && result < 3.775) {
            electricity = 0.45;
        } else if (result >= 3.749 && result < 3.761) {
            electricity = 0.40;
        } else if (result >= 3.739 && result < 3.749) {
            electricity = 0.35;
        } else if (result >= 3.728 && result < 3.739) {
            electricity = 0.30;
        } else if (result >= 3.711 && result < 3.728) {
            electricity = 0.25;
        } else if (result >= 3.690 && result < 3.711) {
            electricity = 0.20;
        } else if (result >= 3.657 && result < 3.690) {
            electricity = 0.15;
        } else if (result >= 3.631 && result < 3.657) {
            electricity = 0.10;
        } else if (result >= 3.577 && result < 3.631) {
            electricity = 0.05;
        } else if (result > 3.330 && result < 3.577) {
            electricity = 0.05;
        } else if (result <= 3.33) {
            electricity = 0.0;
        }
    }
    
    
    if (self.electricityBlock) {
        self.electricityBlock(electricity);
    }
}
#pragma mark ------  处理心电数据

- (void)computeLiveECGData:(NSString *)bytStr byteData:(NSData *)byteData
{
    
    /*
     a表示系数0.97固定    y是高通后的数据，就是上一次结算的结果，这里等于lastResult
     x 是高通前的数据，就是经过getV的算法后的结果，这里等于prevalueArray x1代表n-1倒数第二个数据 x0代表n 就是最后一个数据
     y1=a*y0+a*(x1-x0)     y是高通后的数据 x是高通前的 a是高通系数取值范围0.5-1
     ecg = ((bytes[i] & 0xFF) << 16) | ((bytes[i + 1] & 0xFF) << 8) | ((bytes[i + 2] & 0xFF));这是转化公式
     */
    if (byteData.length < 20) {
        return;
    }
    NSData *eachEcgData = [byteData subdataWithRange:NSMakeRange(2, byteData.length-2)];
  
        [self.ecgData appendData:eachEcgData];
   

    NSMutableArray *countArray = [[NSMutableArray alloc]init];
    bytStr = [bytStr substringWithRange:NSMakeRange(4, [bytStr length]-4)];
    for (int i =0; i<bytStr.length/6; i++){
        [countArray addObject:[bytStr substringWithRange:NSMakeRange(i*6, 6)]];
    }
    
    if (self.preValueArray.count > 6) {
        [self.preValueArray removeObjectsInRange:NSMakeRange(0, self.preValueArray.count - 6)];
    }

    for (int i =0; i<countArray.count; i++) {
        NSString *orgECGValue = [NSString stringWithFormat:@"%lu",strtoul([countArray[i] UTF8String],0,16)];
        CGFloat floatVal = [self computeOrgECGValue:[orgECGValue intValue]];
        [self.preValueArray addObject:@(floatVal)];
        BOOL isFirstValue = self.lastResult == -1001.0 ? YES : NO;
        
        if (isFirstValue) {
            self.lastResult = floatVal;
        }
        
        CGFloat a = 0.97; //系数有具体的算法
        
        if (!isFirstValue) {
            //高通前最后一个数字
            float FloVal1= [[self.preValueArray lastObject] floatValue];
            //高通前倒数第二个数字
            float FloVal2= [self.preValueArray[self.preValueArray.count-2] floatValue];
            //高通后
            float resultFlo = self.lastResult;
            
            float result = a * resultFlo + a * (FloVal1-FloVal2);
            self.lastResult = result;
            if (self.dataBlock) {
                self.dataBlock(result);
            }
        }
    }
}


/*高通前数据计算方法*/
- (CGFloat)computeOrgECGValue:(NSInteger)value
{
    //    CGFloat y = (CGFloat) (a / 16777215.0 / 6.0);
    NSInteger a = (value - 8388608) * 4800;
    NSDecimalNumber *number1 = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%ld",(long)a]];
    NSDecimalNumber *number2 = [NSDecimalNumber decimalNumberWithString:@"16777215"];
    NSDecimalNumber *number3 = [NSDecimalNumber decimalNumberWithString:@"6"];

    
    NSDecimalNumberHandler *handler = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundPlain scale:8 raiseOnExactness:NO raiseOnOverflow:NO raiseOnUnderflow:NO raiseOnDivideByZero:YES];
    NSDecimalNumber *num = [number1 decimalNumberByDividingBy:number2 withBehavior:handler];

    
    NSDecimalNumberHandler *handler1 = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundPlain scale:6 raiseOnExactness:NO raiseOnOverflow:NO raiseOnUnderflow:NO raiseOnDivideByZero:YES];
    NSDecimalNumber *result = [num decimalNumberByDividingBy:number3 withBehavior:handler1];
    return [result floatValue];
}

#pragma mark ----- 内部处理
- (NSData *)getECGByteDataWithError:(NSError **)error
{
//    *error = nil;
//    /*
//     一个包 6个点 一个包20字节 2字节头部，每个点3字节，设备采集是10ms/点, 1s相当于采集100个点
//     最低采集时长为5分钟，5分钟=5*60*100点=30000个点
//     5分钟的字节长度应该为30000点*3字节=90000字节
//     数据不足5分钟可以补点，最大补点数为10s的数据，10s*100点/s * 3字节 = 3000字节
//     */
//    NSInteger timer = [[ElectrocardiographSDK shared]myTestTimer];
//    NSUInteger minSize = timer * 60 * 100 *3;
//    NSUInteger length = self.ecgData.length;
//    NSUInteger offset = 3000;
//    if (length < minSize) {
//        NSUInteger lessCount = minSize - length;
//        if (lessCount > offset) {
//            *error = [NSError errorWithDomain:@"DataExceptionErrorDomain" code:kDDCheckECGDataExceptionLocalError userInfo:nil];
//            [DDBlueIToll DDLog:@"ecg数据长度不足规定时间不过可以根据自身情况修改"];
//            return nil;
//        } else {
//            for (int i = 0; i < lessCount; i++) {
//                Byte byte[] = {0x00};
//                [self.ecgData appendData:[NSData dataWithBytes:byte length:1]];
//            }
//            return [self.ecgData copy];
//        }
//    } else {
//        return [self.ecgData copy];
//    }
   /* 上面代码为检查时间内的数据是否为规定长度*/

    return [self.ecgData copy];
}
- (void)clearAllLastState
{
    self.currentFlowState = DDFlowStateWait;
    self.lastResult = -1001;
    [self.preValueArray removeAllObjects];
//    self.commondRetryTimes = DDCommondRetryTimes;
    self.ecgData = [[NSMutableData alloc] init];
//    [self.ecgSegmentArray removeAllObjects];
}

#pragma mark ------ DDBlueRequestManagerDelegate


/// 扫描广播
/// @param request ——
/// @param peripheral ——
/// @param advertisementData ——
/// @param RSSI ——
- (void)isTargetDevice:(DDHeartRateCheckRequest * )request
                peripheral:(CBPeripheral *)peripheral
         advertisementData:(NSDictionary<NSString *,id> *)advertisementData
                  RSSI:(NSNumber *)RSSI{
    if ([self.delegate respondsToSelector:@selector(isTargetPeripheral:advertisementData:RSSI:)]) {
        [self.delegate isTargetPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
    }
}

/// 没有搜索到设备
/// @param request ——
- (void)didScanDeviceFail:(DDHeartRateCheckRequest * )request{
    if (self.stateBlock) {
        self.stateBlock(DDHeartRateCheckStateScanDeviceFail);
    }
}

/// 找到了设备
/// @param request ——
- (void)didDiscoverDevice:(DDHeartRateCheckRequest * )request{
    if (self.stateBlock) {
        self.stateBlock(DDHeartRateCheckStateDiscoverDevice);
    }
}

/// ///  连接了周边设备 连接成功 扫描services服务
/// @param request ---
- (void)didConnectDevice:(DDHeartRateCheckRequest * )request{
    if (self.stateBlock) {
        self.stateBlock(DDHeartRateCheckStateConnectDeviceSuccess);
    }
}

/// 连接设备失败
/// @param request ——
- (void)didConnectDeviceFail:(DDHeartRateCheckRequest * )request{
    if (self.stateBlock) {
        self.stateBlock(DDHeartRateCheckStateConnectDeviceFail);
    }
}

/// 设备断开
/// @param request ——
- (void)didDisconnectDevice:(DDHeartRateCheckRequest * )request{
    if (self.stateBlock) {
        self.stateBlock(DDHeartRateCheckStateDeviceDisconnect);
    }
}

/// 找到目标服务
/// @param request ——
- (void)didDiscoverService:(DDHeartRateCheckRequest * )request{
    if (self.stateBlock) {
        self.stateBlock(DDHeartRateCheckStateDiscoverService);
    }
}

/// 已经连接 并且已经找到读写服务
/// @param request ——
- (void)didCompleteServicePrepare:(DDHeartRateCheckRequest * )request{
    self.currentFlowState = DDFlowStateBind;
    if (self.stateBlock) {
        self.stateBlock(DDHeartRateCheckStateStartBindDevice);
    }
    if (_automaticCopy) {
        [self performSelector:@selector(queryDeviceStatus) withObject:nil afterDelay:1.0];
    }
   
}

/// 接收数据
/// @param request ——
/// @param data 数据
- (void)didReceiveData:(DDHeartRateCheckRequest * )request data:(NSData *)data{
    
}

/// 写入数据
/// @param request ——
/// @param error 失败原因
- (void)didWriteData:(DDHeartRateCheckRequest * )request error:(NSError *)error{
    if (error) {
        if (self.stateBlock) {
            self.stateBlock(DDHeartRateCheckStateWriteDataFail);
        }
    }
}

/// 蓝牙的状态
/// @param request ——
/// @param state 状态
- (void)clientDidUpdateState:(DDHeartRateCheckRequest * )request state:(CBManagerState)state{
    DDHeartRateCheckState checkState = DDHeartRateCheckStateUnknown;
    switch (state) {
        case CBManagerStateUnknown:
            [DDBlueIToll DDLog:@"---blue---蓝牙状态-> 未知"];
            break;
        case CBManagerStateResetting:
            checkState = DDHeartRateCheckStateBlueResetting;
            [DDBlueIToll DDLog:@"---blue---蓝牙状态-> 重置"];
            break;
        case CBManagerStateUnsupported:
            [DDBlueIToll DDLog:@"---blue---蓝牙状态-> 不支持"];
            checkState = DDHeartRateCheckStateBlueUnsupported;
            break;
        case CBManagerStateUnauthorized:
            [DDBlueIToll DDLog:@"---blue---蓝牙状态-> 未授权"];
            checkState = DDHeartRateCheckStateBlueUnauthorized;
            break;
        case CBManagerStatePoweredOff:
            [DDBlueIToll DDLog:@"---blue---蓝牙状态-> 关闭"];
            checkState = DDHeartRateCheckStateBluePoweredOff;
            break;
        case CBManagerStatePoweredOn:
            [DDBlueIToll DDLog:@"---blue---蓝牙状态-> 可用"];
            checkState = DDHeartRateCheckStateBluePoweredOn;
            break;
        default:
            break;
    }
    
    if (self.stateBlock) {
        self.stateBlock(checkState);
    }
}

//数据通知错误被停止
- (void)readDataFail:(DDHeartRateCheckRequest * )request error:(NSError *)error{
    if (self.stateBlock) {
        self.stateBlock(DDHeartRateCheckStateReadDataFail);
    }
}


/// 心电实时传输的数据这个是用来绘制心电图
/// @param requestManager ——
/// @param byteStr 字节
/// @param byteData 字节
- (void)didReceiveLiveECGData:(DDHeartRateCheckRequest *)requestManager byteStr:(NSString * _Nullable)byteStr byteData:(NSData *)byteData{
    
    
    [self computeLiveECGData:byteStr byteData:byteData];
}

@end
