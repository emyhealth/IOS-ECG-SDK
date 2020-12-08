//
//  ElectrocardiographSDK.m
//  ElectrocardiographSDK
//
//  Created by tanshushu on 2020/11/10.
//

#import "ElectrocardiographSDK.h"
static ElectrocardiographSDK *instance = nil;
@implementation ElectrocardiographSDK

+ (instancetype)shared
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ElectrocardiographSDK alloc]init];
        [[NSUserDefaults standardUserDefaults]setBool:NO forKey:@"DDProduction"];
        [[NSUserDefaults standardUserDefaults]setInteger:5 forKey:@"DDTestTimer"];
    });
    return instance;
}


- (void)setProduction:(BOOL)production{
    [[NSUserDefaults standardUserDefaults]setBool:production forKey:@"DDProduction"];
}

- (void)setTestTimer:(NSInteger)testTimer{
    [[NSUserDefaults standardUserDefaults]setInteger:testTimer forKey:@"DDTestTimer"];
}
/// 获取测试时间
-(NSInteger)myTestTimer{
    return [[NSUserDefaults standardUserDefaults]integerForKey:@"DDTestTimer"];
}
@end
