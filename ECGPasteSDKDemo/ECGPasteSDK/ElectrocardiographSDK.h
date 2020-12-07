//
//  ElectrocardiographSDK.h
//  ElectrocardiographSDK
//
//  Created by tanshushu on 2020/11/10.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

@interface ElectrocardiographSDK : NSObject


/// 初始化
+ (instancetype)shared;

///是否生产环境.Debug模式用于向控制台打印日志，prod模式关闭打印日志的功能
@property(nonatomic,assign)BOOL production;


/// 检测时间
@property(nonatomic,assign)NSInteger testTimer;

/// 获取测试时间
-(NSInteger)myTestTimer;
@end

NS_ASSUME_NONNULL_END
