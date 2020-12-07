//
//  DDHeartRateCheckRequest.h
//  ElectrocardiographSDK
//
//  Created by tanshushu on 2020/11/11.
//

#import <Foundation/Foundation.h>
#import "DDCommandTask.h"
#import "DDHeartRateCheckConfig.h"
#import "DDBluetoothClient.h"
NS_ASSUME_NONNULL_BEGIN
@protocol DDBlueRequestManagerDelegate <NSObject>


/// 扫描广播
/// @param request ——
/// @param peripheral ——
/// @param advertisementData ——
/// @param RSSI ——
- (void)isTargetDevice:(DDHeartRateCheckRequest * )request
                peripheral:(CBPeripheral *)peripheral
         advertisementData:(NSDictionary<NSString *,id> *)advertisementData
                      RSSI:(NSNumber *)RSSI;

/// 没有搜索到设备
/// @param request ——
- (void)didScanDeviceFail:(DDHeartRateCheckRequest * )request;

/// 找到了设备
/// @param request ——
- (void)didDiscoverDevice:(DDHeartRateCheckRequest * )request;

/// ///  连接了周边设备 连接成功 扫描services服务
/// @param request ---
- (void)didConnectDevice:(DDHeartRateCheckRequest * )request;

/// 连接设备失败
/// @param request ——
- (void)didConnectDeviceFail:(DDHeartRateCheckRequest * )request;

/// 设备断开
/// @param request ——
- (void)didDisconnectDevice:(DDHeartRateCheckRequest * )request;

/// 找到目标服务
/// @param request ——
- (void)didDiscoverService:(DDHeartRateCheckRequest * )request;

/// 已经连接 并且已经找到读写服务
/// @param request ——
- (void)didCompleteServicePrepare:(DDHeartRateCheckRequest * )request;

/// 接收数据
/// @param request ——
/// @param data 数据
- (void)didReceiveData:(DDHeartRateCheckRequest * )request data:(NSData *)data;

/// 写入数据
/// @param request ——
/// @param error 失败原因
- (void)didWriteData:(DDHeartRateCheckRequest * )request error:(NSError *)error;

/// 蓝牙的状态
/// @param request ——
/// @param state 状态
- (void)clientDidUpdateState:(DDHeartRateCheckRequest * )request state:(CBManagerState)state;

//数据通知错误被停止
- (void)readDataFail:(DDHeartRateCheckRequest * )request error:(NSError *)error;


/// 心电实时传输的数据这个是用来绘制心电图
/// @param requestManager ——
/// @param byteStr 字节
/// @param byteData 字节
- (void)didReceiveLiveECGData:(DDHeartRateCheckRequest *)requestManager byteStr:(NSString * _Nullable)byteStr byteData:(NSData *)byteData;

@end

/// 这个类主要做蓝牙的交互数据的判断等等
@interface DDHeartRateCheckRequest : NSObject
@property (nonatomic, weak) id <DDBlueRequestManagerDelegate> delegate;
/// 开始扫描
- (void)startCheck;

///// 结束任务
//- (void)enterCloseCheckState;

/// 做任务
/// @param task 任务模型
- (void)sendRequestWithTask:(DDCommandTask *)task;

/// 停止
///signOut yes表示退出程序

- (void)closeBlutoothConnect:(BOOL )signOut;
//停止扫描设备
- (void)stopScan;

/// 选择的设备信息
/// @param peripheral 代理里面传递的
/// @param advertisementData 代理里面传递的
-(void)chooseDevicePeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString*,id> *)advertisementData;
@end

NS_ASSUME_NONNULL_END
