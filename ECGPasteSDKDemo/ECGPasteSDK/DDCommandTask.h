//
//  DDCommandTask.h
//  healthCheck
//
//  Created by admin on 2019/10/24.
//  Copyright © 2019 xlf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDHeartRateCheckConfig.h"

NS_ASSUME_NONNULL_BEGIN

@class DDHeartRateCheckRequest;

typedef  NS_ENUM(NSInteger, DDCommandTaskErrorType) {
    DDCommandTaskErrorTypeTimeOut,                //超时，内部已经对task进行重试
    DDCommandTaskErrorTypeCommandError,           //指令错误
    DDCommandTaskErrorTypeBluetoothError,         //蓝牙连接失败，包括写失败和链路断开，链路不可用，这种失败无需要回调后处理,因为蓝牙状态已经有处理
    DDCommandTaskErrorTypeAutoStopTaskError       //当手动停止采集的时候，如果此时还在发送其他命令，此时返回 并不做业务层错误提示
};

#define DDCommandTaskRetryTimes         3

#define DDCommandTaskDuration           30          //总超时时间30s

typedef void (^DDCommandTaskSuccessBlock)(BOOL success, NSString *byteStr);

typedef void (^DDCommandTaskFailBlock)(DDCommandTaskErrorType errType, NSString *errorInfo);

@interface DDCommandTask : NSObject

/// 指令类型
@property(nonatomic, assign) DDBLECommandType type;

/// 成功
@property(nonatomic, copy) DDCommandTaskSuccessBlock successBlock;
//失败
@property(nonatomic, copy) DDCommandTaskFailBlock failBlock;

@property(nonatomic, assign) NSInteger commandErrorRetryTimes; //命令错误oxe8ff00 默认3次

@property(nonatomic, assign) NSInteger responseFailRetryTimes; //相应结果失败，重试次数 默认3次

@property(nonatomic, assign) NSInteger duration; //当前超时经过时间默认3秒

+ (instancetype)createTaskWithType:(DDBLECommandType)type request:(DDHeartRateCheckRequest *)request success:(DDCommandTaskSuccessBlock)success fail:(DDCommandTaskFailBlock)fail;

- (NSData *)encodeCommand;

- (void)resume;

@end

NS_ASSUME_NONNULL_END
