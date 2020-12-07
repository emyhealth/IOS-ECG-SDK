//
//  DDBluetoothClient.h
//  healthCheck
//
//  Created by admin on 2019/10/23.
//  Copyright © 2019 xlf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#define DDBuildConnectRetryTimes        3

#define DDScanDeviceTimeout             15

#define DDConnectDeviceTimeout           30

#define DDBluetoothWriteDataRetryTimes         3           //蓝牙发送失败重试次数

NS_ASSUME_NONNULL_BEGIN

@class DDBluetoothClient;

//初始化-->扫描(直接状态可用扫描，状态更新为可用后扫描)-->扫描到设备-->连接设备-->寻找服务-->发现服务-->寻找特征-->发现特征-->配到到可用读写特征-->准备完成
@protocol DDBlueClientDelegate <NSObject>

@optional

/// 初始化
/// @param client ——
- (void)startPrepareService:(DDBluetoothClient * _Nullable)client;

/// 开始扫描
/// @param client ——
- (void)startScanDevice:(DDBluetoothClient * _Nullable)client;

/// 扫描广播
/// @param client ——
/// @param peripheral ——
/// @param advertisementData ——
/// @param RSSI ——
- (void)isTargetDevice:(DDBluetoothClient * _Nullable)client
                peripheral:(CBPeripheral *)peripheral
         advertisementData:(NSDictionary<NSString *,id> *)advertisementData
                      RSSI:(NSNumber *)RSSI;

/// 没有搜索到设备
/// @param client ——
- (void)didScanDeviceFail:(DDBluetoothClient * _Nullable)client;

/// 找到了设备
/// @param client ——
- (void)didDiscoverDevice:(DDBluetoothClient * _Nullable)client;

///  连接了周边设备 连接成功 扫描services服务
/// @param client _---
- (void)didConnectDevice:(DDBluetoothClient * _Nullable)client;

/// 连接设备失败
/// @param client ——
- (void)didConnectDeviceFail:(DDBluetoothClient * _Nullable)client;

/// 设备断开
/// @param client ——
- (void)didDisconnectDevice:(DDBluetoothClient * _Nullable)client;

/// 找到目标服务
/// @param client ——
- (void)didDiscoverService:(DDBluetoothClient * _Nullable)client;

/// 已经连接 并且已经找到读写服务
/// @param client ——
- (void)didCompleteServicePrepare:(DDBluetoothClient * _Nullable)client;

/// 接收数据
/// @param client ——
/// @param data 数据
- (void)didReceiveData:(DDBluetoothClient *)client data:(NSData *)data;

/// 写入数据
/// @param client ——
/// @param error 失败原因
- (void)didWriteData:(DDBluetoothClient *)client error:(NSError *)error;

/// 蓝牙的状态
/// @param client ——
/// @param state 状态
- (void)clientDidUpdateState:(DDBluetoothClient *)client state:(CBManagerState)state;


- (void)readDataFail:(DDBluetoothClient *)client error:(NSError *)error; //数据通知错误被停止

@end

@interface DDBluetoothClient : NSObject

@property (nonatomic, weak) id <DDBlueClientDelegate> delegate;

@property (nonatomic, copy) NSString *bluetoothDeviceName;

@property (nonatomic, copy) NSString *bluetoothServiceUUID;

@property (nonatomic, copy) NSString *characteristicReadUUID;

@property (nonatomic, copy) NSString *characteristicWriteUUID;

@property (nonatomic, copy) NSString *bluetoothDeviceMac;

@property (nonatomic, assign) NSInteger connectRetryTimes; //蓝牙连接重试次数

@property (nonatomic, assign) BOOL isOnlySearchDevice;

@property (nonatomic, assign) BOOL enableScanTimeout;

//@property (nonatomic, assign) DDDeviceType deviceType;

/**
 *  开始执行
 */
- (void)startRunning;

/**
 是否已经连接
 */
- (BOOL)isConnected;
/**
 断开连接
 signOut yes表示退出程序
 */
- (void)disconnect:(BOOL )signOut;

/// 停止扫描设备并断开连接

- (void)stopScanAndDisconnect;

//停止扫描设备
- (void)stopScan;

- (void)reScanBluethoothDevice;
/**
 发送数据
 
 @param data NSData数据
 */
- (void)sendData:(NSData *)data;

/// 连接设备
/// @param peripheral 选择的设备
- (void)startConnectPeripheral:(CBPeripheral *)peripheral;
@end

NS_ASSUME_NONNULL_END
