# IOS-ECG-SDK
心电记录仪sdk
# ECG-SDK
  ECG-SDK是由颐麦科技开发，主要用于简化对接BW-ECG-CHA型号心电检测设备的流程以及数据采集
## 1.基础用法
### 1).获取DDHeartRateCheckManager并初始化并扫描设备
```oc
   //automatic 是否需要自动采集数据如不需要就需要自己调用发送指令
    [[DDHeartRateCheckManager shared] startCheckAutomatic:<#(BOOL)#>];
    [DDHeartRateCheckManager shared].delegate = self;
```
### 2).开始检测
```oc
 
    //DDHeartRateCheckManagerDelegate
 /// 扫描得到广播选取你要连接点设备
/// @param peripheral ——
/// @param advertisementData ——
/// @param RSSI ——
- (void)isTargetPeripheral:(CBPeripheral *)peripheral
         advertisementData:(NSDictionary<NSString *,id> *)advertisementData
                      RSSI:(NSNumber *)RSSI;
  //去连接设备
  [[DDHeartRateCheckManager shared] chooseDevicePeripheral:<#(nonnull CBPeripheral *)#> advertisementData:<#(nonnull NSDictionary<NSString *,id> *)#>];
```
### 3).停止检测
```oc
 /// 停止一切操作 并且断开连接 YES表示退出程序 蓝牙断开对象释放  NO 表示断开蓝牙连接还可以继续连接
 [[DDHeartRateCheckManager shared] endCheck:<#(BOOL)#>];
```
### 4).停止扫描
```oc
    [[DDHeartRateCheckManager shared] stopScan];
```
### 5).获取数据
```oc
        NSError *error;
      //得到的检测时间内的原始数据用于上传分析
    NSData *data = [[DDHeartRateCheckManager shared] getECGByteDataWithError:&error];
       
    [DDHeartRateCheckManager shared].dataBlock = ^(CGFloat value) {
        //单点的高通数据格式回调的block，便于绘图
    };
    [DDHeartRateCheckManager shared].electricityBlock = ^(CGFloat electricity) {
        NSLog(@"设备电量%f",electricity);
    };
    [DDHeartRateCheckManager shared].stateBlock = ^(DDHeartRateCheckState state) {
      // 这里需要对应这个DDHeartRateCheckState枚举查看状态
        NSLog(@"当前状态-----%u",state);
    };
    
```

## 3.进阶用法
### 1)自定义指令处理流顺序
指令发送流程如下：
**查询设备状态—>设置设备时间—>绑定用户—>开始采集—>开始传输**
（注意：查询设备状态后发现是待机状态下才执行后续操作，否则会先发送停止采集指令使设备恢复至待机状态，然后重新执行后续流程）

开发者若需要自己自定义处理流程时，可通过以下方法设置
注意：**查询设备状态、绑定用户、开始采集、开始传输**这三个指令操作不可省略
```oc
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
```
### 2)仅使用该SDK提供的指令
当开发者不想使用本SDK执行检测，仅想使用本库提供的指令时，使用以下指令工厂得到相应指令即可
```oc
    //获取指令工厂
    DDCommandTask *task = [[DDCommandTask alloc]init];
   task.type = DDBLECommandTypeQueryState;
   //获取指令指令
   NSData *data = [task encodeCommand];
```
### 3)设置 ElectrocardiographSDK提供了如下方法

```oc
   /// 初始化
+ (instancetype)shared;

///是否生产环境.Debug模式用于向控制台打印日志，prod模式关闭打印日志的功能
@property(nonatomic,assign)BOOL production;


/// 检测时间
@property(nonatomic,assign)NSInteger testTimer;

/// 获取测试时间
-(NSInteger)myTestTimer; 
```




