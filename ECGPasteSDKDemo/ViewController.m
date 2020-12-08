//
//  ViewController.m
//  ECGPasteSDKDemo
//
//  Created by tanshushu on 2020/11/26.
//

#import "ViewController.h"
#import "DDHeartRateCheckManager.h"
#import "DDECGChart.h"
#import "UIScreen+DDSizeTransfrom.h"
#import "ElectrocardiographSDK.h"
#define  SCREENWIDTH ([UIScreen mainScreen].bounds.size.width)
#define  SCREENHEIGHT ([UIScreen mainScreen].bounds.size.height)
#define DDLeftPadding   15

@interface ViewController ()<DDHeartRateCheckManagerDelegate,UITableViewDelegate,UITableViewDataSource>
@property(nonatomic,strong)NSMutableArray *dataSoure;
@property(nonatomic,strong)UITableView *tableview;
@property(nonatomic,strong)DDHeartRateCheckManager *manager;
@property(nonatomic,strong)UIButton *button;
@property (nonatomic, strong) DDECGChart *canvasView;
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation ViewController

/*！！！！！！！！！！！！使用前需要先设置plist文件如果你需要在后台运行则需要打开一些后台可参考demo*/

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    _dataSoure = [[NSMutableArray alloc]init];
   _manager = [DDHeartRateCheckManager shared];
    _manager.delegate = self;
    __weak typeof(self)weakSelf = self;
    _manager.dataBlock = ^(CGFloat value) {
        [weakSelf.canvasView addECGPointWithValue:value];
    };
    _manager.electricityBlock = ^(CGFloat electricity) {
        NSLog(@"设备电量%f",electricity);
    };
    _manager.stateBlock = ^(DDHeartRateCheckState state) {
//        这里需要对应这个DDHeartRateCheckState枚举查看状态
        NSLog(@"当前状态-----%u",state);
    };
    [_manager startCheckAutomatic:YES];

    CGFloat sEach = [UIScreen getPerMillimetreOfPT];
    NSInteger count = ceilf((SCREENWIDTH - 2*DDLeftPadding)/sEach);
    CGFloat width = count * sEach + 0.5;
    CGFloat height = 8 * sEach * 5 + 1;
    self.canvasView = [[DDECGChart alloc] init];
    self.canvasView.frame = CGRectMake(DDLeftPadding, 10, width, height);
    [self.view addSubview:self.canvasView];
    
    _tableview = [[UITableView alloc]initWithFrame:CGRectMake(0, height+10, SCREENWIDTH, SCREENHEIGHT-height-10) style:UITableViewStylePlain];
    _tableview.delegate = self;
    _tableview.dataSource = self;
    [self.view addSubview:_tableview];
   _button = [UIButton buttonWithType:UIButtonTypeCustom];
    _button.frame = CGRectMake(SCREENWIDTH-80, height +40, 60, 60);
    [_button setTitle:@"刷新" forState:UIControlStateNormal];
    [_button addTarget:self action:@selector(refresh) forControlEvents:UIControlEventTouchUpInside];
    [_button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [self.view addSubview:_button];
}

-(void)refresh{
    
    [self.manager stopScan];
    [_dataSoure removeAllObjects];
    [_tableview reloadData];
    [_manager startCheckAutomatic:YES];
  
}

- (void)isTargetPeripheral:(nonnull CBPeripheral *)peripheral advertisementData:(nonnull NSDictionary<NSString *,id> *)advertisementData RSSI:(nonnull NSNumber *)RSSI {
    
    //在这里可以做判断不一定需要列表展示这里只是方便测试（可以找到相应的直接连接） 目前我们的设备名都是ECG-AOOO没有mac地址/BW-ECG-01 5.0设备data10个字节（如0x0081f9624ee8ff039fdc），前六个字节表示mac地址，后四个字节0xFF为flash可用量，0x03为采集状态，0x9fdc为电量 开头 所以只要mac地址一样则表示是同一台设备电量是随时会发生改变的
    
    //这里展示没有去过滤所以会出现重复的设备展示所以只要mac地址一样则表示是同一台设备电量是随时会发生改变的 ECG-AOOO没有mac地址所以用名称作为依据
    NSDictionary *dict = @{@"peripheral":peripheral,@"advertisementData":advertisementData,@"RSSI":RSSI};
    NSLog(@"%@",advertisementData);
    [_dataSoure addObject:dict];
    [_tableview reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _dataSoure.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
   
    NSDictionary *dict = _dataSoure[indexPath.row][@"advertisementData"];
    CBPeripheral *peripheral = _dataSoure[indexPath.row][@"peripheral"];
    cell.textLabel.text = [NSString stringWithFormat:@"%@/%@",peripheral.name,[self hexStringFromString:dict[@"kCBAdvDataManufacturerData"]]];//前面为蓝牙名称，后面为mac地址但是我们5.0以下的设备是没有mac地址的。
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.canvasView clearECG];
    //连接设备
    [_manager chooseDevicePeripheral: _dataSoure[indexPath.row][@"peripheral"] advertisementData:_dataSoure[indexPath.row][@"advertisementData"]];
    NSInteger timer = [[ElectrocardiographSDK shared]myTestTimer];
    //这里的的时间需要减去去连接绑定等时间例如:设置为5秒但实际连接,绑定共花费了1秒实际检测时间为4秒需要根据自身情况来设置
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timer * 60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.manager endCheck:NO];
        [self.canvasView stopDrawECG];
        NSError *error;
        //得到的所有数据
        NSData *data = [self.manager getECGByteDataWithError:&error];
        NSLog(@"");
    });
   
    [_dataSoure removeAllObjects];
    [_tableview reloadData];
}






- (NSString *)hexStringFromString:(NSData *)data{
    Byte *bytes = (Byte *)[data bytes];
    //下面是Byte转换为16进制。
    NSString *hexStr=@"";
    for(int i=0;i<[data length];i++){
        NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff];///16进制数
        if([newHexStr length]==1)
            hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
        else
            hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
    }
    return hexStr;
}
@end
