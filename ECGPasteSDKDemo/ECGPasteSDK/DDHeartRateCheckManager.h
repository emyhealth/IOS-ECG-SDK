//
//  DDHeartRateCheckManager.h
//  ElectrocardiographSDK
//
//  Created by tanshushu on 2020/11/12.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "DDCommandTask.h"
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

typedef  NS_ENUM(NSInteger, DDFlowState) {
    DDFlowStateWait = 0,        //默认状态，或者结束完成状态
    DDFlowStateBind,            //bind中
    DDFlowStateCollect,         //执行单机采集
    DDFlowStateLiveECG,         //执行实时传输
    DDFlowStateTurnOffCollect,  //结束单机采集
};

typedef  NS_ENUM(NSInteger, DDDeviceState) {
    DDDeviceStateAwait = 0,         //待机
    DDDeviceStateLiveCollect,       //实时采集 就是边采集边传输
    DDDeviceStateSyncCollect,       //同步采集
    DDDeviceStateOfflineCollect,    //单机采集
};
typedef enum DDHeartRateCheckState {
    //蓝牙连接状态
    DDHeartRateCheckStateStartPrepare   = 0,            //检测开始->连接，包括扫描 连接 发现服务 发现特征
    DDHeartRateCheckStateScanDevice,                    //开始扫描设备
    DDHeartRateCheckStateScanDeviceFail,                //未发现目标设备
    DDHeartRateCheckStateDiscoverDevice,                //找到目标设备
    DDHeartRateCheckStateConnectDeviceSuccess,          //连接设备成功
    DDHeartRateCheckStateConnectDeviceFail,             //连接设备失败
    DDHeartRateCheckStateDeviceDisconnect,              //设备断开
    DDHeartRateCheckStateDiscoverService,               //找到目标服务
    DDHeartRateCheckStateCompletePrepare,               //蓝牙准备完成
    DDHeartRateCheckStateExceptionFinish,                  //逻辑断开蓝牙设备
    DDHeartRateCheckStateWriteDataFail,                 //蓝牙写入数据失败
    DDHeartRateCheckStateReadDataFail,                 //订阅特征数据通知被停止
//    11
    //蓝牙状态
    DDHeartRateCheckStateBlueResetting,                 //蓝牙重置
    DDHeartRateCheckStateBlueUnsupported,               //设备不支持
    DDHeartRateCheckStateBlueUnauthorized,              //设备未授权
    DDHeartRateCheckStateBluePoweredOff,                //设备未打开
    DDHeartRateCheckStateBluePoweredOn,                 //设备可用
    
    //心电检测业务状态
    DDHeartRateCheckStateStartBindDevice,               //开始bind设备
    DDHeartRateCheckStateBindSuccess,                   //bind设备成功
    DDHeartRateCheckStateBindFail,                      //bind设备失败
    DDHeartRateCheckStateStartLiveECGSuccess,           //开始实时传输成功
    DDHeartRateCheckStateCollectSuccess,                //采集成功
    DDHeartRateCheckStateCollectFali,                   //采集失败
    DDHeartRateCheckStateStopCollect,                   //停止采集
    DDHeartRateCheckStateStopCollectSuccess,            //停止采集成功
    DDHeartRateCheckStateStopCollectFail,               //停止采集失败
    DDHeartRateCheckStateServiceError,                  //服务异常,一般指报08ff00000000的错误 或 执行查询指令后，根据指令进行发送逻辑修正指令失败，例如L：先bind，bind失败，再查询，查询结果设备在采集，此时逻辑停止采集然后再bind，结果停止采集指令失败
    DDHeartRateCheckStateCommandSendTimeout,            //服务指令异常
    DDHeartRateCheckStateUnknown,         // 未知
}DDHeartRateCheckState;

/**
 一单点的高通数据格式回调的block，便于绘图

 @param value 每个心电高通后的数据
 */
typedef void (^DDCheckDataBlock)(CGFloat value);
/**
 返回当前电量的block，目前只在进行逻辑查询状态的时候更新

 @param electricity float值，电量百分比
 */
typedef void (^DDCheckElectricityBlock)(CGFloat electricity);

/**
 检测状态的block
 
 */
typedef void(^DDCheckStateBlcok)(DDHeartRateCheckState state);



@protocol DDHeartRateCheckManagerDelegate <NSObject>

/// 扫描得到广播
/// @param peripheral ——
/// @param advertisementData ——
/// @param RSSI ——
- (void)isTargetPeripheral:(CBPeripheral *)peripheral
         advertisementData:(NSDictionary<NSString *,id> *)advertisementData
                      RSSI:(NSNumber *)RSSI;

@end
@interface DDHeartRateCheckManager : NSObject

/// 代理
@property(nonatomic,weak)id <DDHeartRateCheckManagerDelegate> delegate;

/// 高通后的心电数据用于绘制心电图
@property (nonatomic, copy) DDCheckDataBlock dataBlock;

/// 设备电量
@property (nonatomic, copy) DDCheckElectricityBlock electricityBlock;

/// 设备状态
@property (nonatomic, copy) DDCheckStateBlcok stateBlock;


/// 初始化
+ (instancetype)shared;


//=============================================自动模式者只需要调用以下方式============================================

/// 开始操作这时
/// @param automatic 是否需要自动采集数据如不需要就需要自己调用发送指令如需要只需调用：开始操作，停止一切操作 并且断开连接，停止扫描设备 选择一台设备信息连接这四个方法即可其他
- (void)startCheckAutomatic:(BOOL)automatic;



/// 停止一切操作 并且断开连接
///signOut YES表示退出程序 蓝牙断开对象释放  NO 表示断开蓝牙连接还可以继续连接
- (void)endCheck:(BOOL )signOut;

//停止扫描设备
- (void)stopScan;

/// 选择一台设备信息连接
/// @param peripheral 代理里面传递的
/// @param advertisementData 代理里面传递的
-(void)chooseDevicePeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString*,id> *)advertisementData;

///  获取蓝牙采集设备的心电图ECG原始数据 这个需要采集完毕后在获取
/// @param error 错误
- (NSData *)getECGByteDataWithError:(NSError **)error;




//=============================================调用外部API如用自动模式者不需要调用============================================


/// 该方法用于查询心电记录仪的设备状态，包括：电压值、设备运行状态（采集、待机）
/// @param successRequest 成功返回数据
/// @param failRequest 失败
-(void)queryDeviceStatusSuccess:(void (^)(BOOL success, NSString *byteStr))successRequest fail:(void (^)(DDCommandTaskErrorType errType,NSString *errrorInfo))failRequest;


/// 该方法用于返回心电记录仪的设备型号。
/// @param successRequest 成功返回数据
/// @param failRequest 失败
-(void)queryDeviceModelSuccess:(void (^)(BOOL success, NSString *byteStr))successRequest fail:(void (^)(DDCommandTaskErrorType errType,NSString *errrorInfo))failRequest;


/// 该方法用于返回心电记录仪的设备时间。
/// @param successRequest 成功返回数据
/// @param failRequest 失败
-(void)queryDeviceTimerSuccess:(void (^)(BOOL success, NSString *byteStr))successRequest fail:(void (^)(DDCommandTaskErrorType errType,NSString *errrorInfo))failRequest;


/// 该方法用于向心电记录仪绑定用户信息，设备用户id与该次检测的关联关系。返回成功或者失败
/// @param successRequest 成功返回数据
/// @param failRequest 失败
-(void)bindUserIdSuccess:(void (^)(BOOL success, NSString *byteStr))successRequest fail:(void (^)(DDCommandTaskErrorType errType,NSString *errrorInfo))failRequest;

/// 该方法用于向心电记录仪装订时间，用于纠正心电记录仪时钟的时间。返回成功或者失败；
/// @param successRequest 成功返回数据
/// @param failRequest 失败
-(void)subscribeTimeSuccess:(void (^)(BOOL success, NSString *byteStr))successRequest fail:(void (^)(DDCommandTaskErrorType errType,NSString *errrorInfo))failRequest;

/// 该方法用于向心电记录仪发送开始采集的指令，返回成功或者失败。失败的原因（存储空间不足，电量不足，其他）
/// @param successRequest 成功返回数据
/// @param failRequest 失败
-(void)StartCollectSuccess:(void (^)(BOOL success, NSString *byteStr))successRequest fail:(void (^)(DDCommandTaskErrorType errType,NSString *errrorInfo))failRequest;

/// 该方法用于向心电记录仪发送实时传输采集的指令，返回成功或者失败
/// @param successRequest 成功返回数据
/// @param failRequest 失败
-(void)typeLiveECGSuccess:(void (^)(BOOL success, NSString *byteStr))successRequest fail:(void (^)(DDCommandTaskErrorType errType,NSString *errrorInfo))failRequest;

/// 该方法用于向心电记录仪发送停止实时传输的指令。返回成功或者失败
/// @param successRequest 成功返回数据
/// @param failRequest 失败
-(void)TurnOffLiveECGSuccess:(void (^)(BOOL success, NSString *byteStr))successRequest fail:(void (^)(DDCommandTaskErrorType errType,NSString *errrorInfo))failRequest;

/// 该方法用于向心电记录仪发送结束采集的指令，返回成功或者失败
/// @param successRequest 成功返回数据
/// @param failRequest 失败
-(void)turnOffCollectSuccess:(void (^)(BOOL success, NSString *byteStr))successRequest fail:(void (^)(DDCommandTaskErrorType errType,NSString *errrorInfo))failRequest;


/// 向心电记录仪发送数据
/// @param type 数据类型
/// @param successRequest 成功
/// @param failRequest 失败
-(void)turnOffCollect:(DDBLECommandType)type Success:(void (^)(BOOL success, NSString *byteStr))successRequest fail:(void (^)(DDCommandTaskErrorType errType,NSString *errrorInfo))failRequest;






@end

NS_ASSUME_NONNULL_END
