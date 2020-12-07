//
//  UIScreen+DDSizeTransfrom.h
//  healthCheck
//
//  Created by admin on 2019/11/29.
//  Copyright © 2019 xlf. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIScreen (DDSizeTransfrom)

/**
 获取设备1mm的pt大小

 @return 1mm的pt开发尺寸大小
 */
+ (CGFloat)getPerMillimetreOfPT;


/**
 获取设备物理尺寸，英寸

 @return 返回设备英寸大小
 */
+ (CGFloat)getPhysicalSize;

@end

NS_ASSUME_NONNULL_END
