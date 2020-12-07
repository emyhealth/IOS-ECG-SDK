//
//  DDBluetoothClient.m
//  healthCheck
//
//  Created by admin on 2019/10/23.
//  Copyright © 2019 xlf. All rights reserved.
//

#import "DDBluetoothClient.h"
#import "DDBlueIToll.h"

#define kDDPeripheralIdentifier @"kDDPeripheralIdentifier"

@interface DDBluetoothClient ()<CBCentralManagerDelegate,CBPeripheralDelegate>

@property (nonatomic, strong) CBCentralManager *centralManager;

@property (nonatomic, strong) CBPeripheral *peripheral;

@property (nonatomic, strong) CBCharacteristic *writeCharacteristic;

@property (nonatomic, strong) CBCharacteristic *readCharacteristic;

@property (nonatomic , assign) CBManagerState centralState;

@property (nonatomic, assign) NSInteger writeDataRetryTimes; //停止实时采集失败重试次数

@property (nonatomic, strong) NSData *currentSendData;

@end


@implementation DDBluetoothClient

- (instancetype)init
{
    self = [super init];
    if (self) {
        _connectRetryTimes = DDBuildConnectRetryTimes;
        _writeDataRetryTimes = DDBluetoothWriteDataRetryTimes;
    }
    return self;
}

//开始初始化并扫描设备
- (void)startRunning
{
    if ([self.delegate respondsToSelector:@selector(startPrepareService:)]) {
        [self.delegate startPrepareService:self];
    }
    
    [self clearAllLastState];
    
    if ([self isConnected] && self.writeCharacteristic && self.readCharacteristic) {
        if ([self.delegate respondsToSelector:@selector(didCompleteServicePrepare:)]) {
            [self.delegate didCompleteServicePrepare:self];//已经连接
        }
    } else {
        if (self.peripheral) {
            self.peripheral.delegate = nil;
            [self.centralManager cancelPeripheralConnection:self.peripheral];
            self.peripheral = nil;
        }
//        CBManagerStatePoweredOn,//蓝牙可用
        if (self.centralManager && self.centralManager.state == CBManagerStatePoweredOn) {
                [self startScanPeripheral];
        } else {
            _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        }
    }
}

- (BOOL)isConnected
{
//    CBPeripheralStateConnected 已经连接
    return self.peripheral && self.peripheral.state == CBPeripheralStateConnected;
}

- (void)disconnect:(BOOL )signOut
{
    [self stopBluethoothWork:signOut];
}

- (void)stopScanAndDisconnect
{
    [self stopScan];
    [self disconnect:YES];
}

- (void)reScanBluethoothDevice
{
    if (self.centralManager) {
        //    扫描周围的蓝牙
        [self.centralManager scanForPeripheralsWithServices:nil options:nil];
    } else {
        [self startRunning];
    }
}
//停止扫描设备
- (void)stopScan
{
    [_centralManager stopScan];
}

- (void)startScanPeripheral
{
   
    if ([self.delegate respondsToSelector:@selector(startScanDevice:)]) {
        [self.delegate startScanDevice:self];
    }
    
//    扫描周围的蓝牙
    [self.centralManager scanForPeripheralsWithServices:nil options:nil];
    [self performSelector:@selector(checkDeviceScan) withObject:nil afterDelay:DDScanDeviceTimeout];
}

- (void)checkDeviceScan
{
    if (!self.peripheral) {
      
        [self stopBluethoothWork:NO];
        if ([self.delegate respondsToSelector:@selector(didScanDeviceFail:)]) {
            [self.delegate didScanDeviceFail:self];
        }
    }
}

- (void)startConnectPeripheral:(CBPeripheral *)peripheral
{
   
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkDeviceScan) object:nil];
    if ([self.delegate respondsToSelector:@selector(didDiscoverDevice:)]) {
        [self.delegate didDiscoverDevice:self];
    }
   
    self.peripheral = peripheral;
    [self.centralManager stopScan];
    self.peripheral.delegate = self;
    [self.centralManager connectPeripheral:peripheral options:@{CBConnectPeripheralOptionNotifyOnConnectionKey:@YES, CBConnectPeripheralOptionNotifyOnDisconnectionKey:@YES, CBConnectPeripheralOptionNotifyOnNotificationKey:@YES}];
    if (!self.enableScanTimeout) {
        [self performSelector:@selector(checkDeviceConnect) withObject:nil afterDelay:DDConnectDeviceTimeout];
    }
}

- (void)retryConnectPeripheral
{
    self.peripheral.delegate = self;
    [self.centralManager connectPeripheral:self.peripheral options:nil];
}

- (void)checkDeviceConnect
{
    if (![self isConnected]) {
//        [self stopBluethoothWork];
        if (self.centralManager && self.peripheral) {
            [self.centralManager cancelPeripheralConnection:self.peripheral];
        }
        if ([self.delegate respondsToSelector:@selector(didConnectDeviceFail:)]) {
            [self.delegate didConnectDeviceFail:self];
        }
    }
}

#pragma mark -- CBCentralManagerDelegate
#pragma mark- 先扫描设备--然后连接---发现服务
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    if (!peripheral || !peripheral.name || ([peripheral.name isEqualToString:@""])) {
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(isTargetDevice:peripheral:advertisementData:RSSI:)]) {
        [self.delegate isTargetDevice:self peripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
    }
}

// 连接了周边设备 连接成功 扫描services服务
-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkDeviceConnect) object:nil];
    if ([self.delegate respondsToSelector:@selector(didConnectDevice:)]) {
        [self.delegate didConnectDevice:self];
    }
    
    self.peripheral.delegate = self;
    [self.peripheral discoverServices:nil]; //连接成功直接扫描服务
}

//连接周边蓝牙设备失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
   
    [DDBlueIToll DDLog:[NSString stringWithFormat:@"---blue---设备连接失败!%@",error]];
    if (self.connectRetryTimes > 0) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(retryConnectPeripheral) object:nil];
        self.connectRetryTimes--;
        [self performSelector:@selector(retryConnectPeripheral) withObject:self.currentSendData afterDelay:0.5];
    } else {
        [self stopBluethoothWork:NO];
        if ([self.delegate respondsToSelector:@selector(didConnectDeviceFail:)]) {
            [self.delegate didConnectDeviceFail:self];
        }
    }
}

// 设备断开蓝牙连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{

    [DDBlueIToll DDLog:[NSString stringWithFormat:@"---blue---设备断开蓝牙连接 %@: %@\n", [peripheral name], error]];
    [self stopBluethoothWork:NO];
    if ([self.delegate respondsToSelector:@selector(didDisconnectDevice:)]) {
        [self.delegate didDisconnectDevice:self];
    }
}

// 本机中心设备状态（本机）
-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    
    if ([self.delegate respondsToSelector:@selector(clientDidUpdateState:state:)]) {
        [self.delegate clientDidUpdateState:self state:central.state];
    }
    
    if (central.state != CBManagerStatePoweredOn) {//关闭
        [self stopBluethoothWork:NO];
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
    } else {
        [self startScanPeripheral];//去连接
    }
}

// 状态保存和恢复 暂时不用
-(void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary<NSString *,id> *)dict
{
    //central提供信息，dict包含了应用程序关闭是系统保存的central的信息，用dic去恢复central
    //app状态的保存或者恢复，这是第一个被调用的方法当APP进入后台去完成一些蓝牙有关的工作设置，使用这个方法同步app状态通过蓝牙系统
}

//发现服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    //未发现服务，不可能出现，除非蓝牙名称和我们冲突，所以服务找不到
    if (error != nil || peripheral != self.peripheral) {
        [DDBlueIToll DDLog:@"---blue---Wrong Peripheral.\n"];
        return ;
    }
    
    NSArray *services = [peripheral services];
    if ([services count] == 0) {
      
        return ;
    }
    
    for (CBService *service in services) {
//        NSLog(@"---blue---该设备的service:%@",service);
        if ([[[service.UUID UUIDString] uppercaseString] isEqualToString:[self.bluetoothServiceUUID uppercaseString]]) {
            if ([self.delegate respondsToSelector:@selector(didDiscoverService:)]) {
                [self.delegate didDiscoverService:self];
            }
          
            [peripheral discoverCharacteristics:nil forService:service];
//            return ;
        } else {
           
        }
    }
}

//发现特征,就是设备信号类型
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error) {
       
        return;
    }
    
    //fff0是服务   fff1是读取  fff2是发送
    for (CBCharacteristic *c in service.characteristics) {
     
        if ([[c.UUID.UUIDString uppercaseString] isEqualToString:[self.characteristicWriteUUID uppercaseString]]) {
           
            self.writeCharacteristic = c;
            [_peripheral setNotifyValue:YES forCharacteristic:self.writeCharacteristic];
            if ([self.delegate respondsToSelector:@selector(didCompleteServicePrepare:)]) {
                [self.delegate didCompleteServicePrepare:self];//蓝牙已经连接
            }
        }

        if ([[c.UUID.UUIDString uppercaseString] isEqualToString:[self.characteristicReadUUID uppercaseString]]) {
          
            self.readCharacteristic = c;
            [_peripheral setNotifyValue:YES forCharacteristic:self.readCharacteristic];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(didReceiveData:data:)]) {
        [self.delegate didReceiveData:self data:characteristic.value];
    }
}

//发现外设的特征的描述数组
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    if (error) {
       
    }
    // 在此处读取描述即可
    for (CBDescriptor *descriptor in characteristic.descriptors) {
        [DDBlueIToll DDLog:[NSString stringWithFormat:@"---blue---发现外设的特征descriptor(%@)",descriptor]];
        [self.peripheral readValueForDescriptor:descriptor];
    }
}

//写入指令 是否成功回调
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    if (error) {
        [DDBlueIToll DDLog:[NSString stringWithFormat:@"---blue---特征值=%@ 写入失败 error %@",characteristic.UUID,error.description]];
        if (self.writeDataRetryTimes > 0 && self.peripheral.state == CBPeripheralStateConnected) {
            self.writeDataRetryTimes--;
            [self performSelector:@selector(sendData:) withObject:self.currentSendData afterDelay:0.5];
        } else {
            [self stopBluethoothWork:NO];
            if ([self.delegate respondsToSelector:@selector(didWriteData:error:)]) {
                [self.delegate didWriteData:self error:error];
            }
        }
    } else {
        [DDBlueIToll DDLog:[NSString stringWithFormat:@"---blue---特征值=%@ 写入成功",characteristic.UUID]];
        self.writeDataRetryTimes = DDBluetoothWriteDataRetryTimes;
        if ([self.delegate respondsToSelector:@selector(didWriteData:error:)]) {
            [self.delegate didWriteData:self error:error];
        }
    }
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
       
    }

}


#pragma mark -  commands
- (void)sendData:(NSData *)data
{
    self.currentSendData = data;
    if (self.writeCharacteristic && data) {
        [self.peripheral writeValue:data forCharacteristic:self.writeCharacteristic type:CBCharacteristicWriteWithResponse];
    }
}

/// 断开连接还是退出
/// @param signOut yes表示退出程序
- (void)stopBluethoothWork:(BOOL )signOut
{
    if (!signOut) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        if (self.centralManager && self.peripheral) {
            [self.centralManager cancelPeripheralConnection:self.peripheral];
        }
        return;
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if (self.centralManager && self.peripheral) {
        [self.centralManager cancelPeripheralConnection:self.peripheral];
    }
    
    self.peripheral.delegate = nil;
    self.peripheral = nil;
    self.centralManager.delegate = nil;
    [self.centralManager stopScan];
    self.centralManager = nil;
    self.writeCharacteristic = nil;
    self.readCharacteristic = nil;
    [self clearAllLastState];
}

- (void)clearAllLastState
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.currentSendData = nil;
    self.connectRetryTimes = DDBuildConnectRetryTimes;
    self.writeDataRetryTimes = DDBluetoothWriteDataRetryTimes;
}

- (void)dealloc
{
    NSLog(@"dealloc:%@",self.description);
}

@end


