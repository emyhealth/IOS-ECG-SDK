//
//  NSDecimalNumber+DDExtension.h
//  healthCheck
//
//  Created by admin on 2019/11/14.
//  Copyright © 2019 xlf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, DDMethodsMode) {
    DDMethodsModeAddition,   // Round up on a tie
    DDMethodsModeSubtraction,    // Always down == truncate
    DDMethodsModeMultiplication,      // Always up
    DDMethodsModeDivision  // on a tie round so last digit is even
};

@interface NSDecimalNumber (DDExtension)

/**
 NSDecimalNumber计算
 
 @param str1 数字字符串1
 @param str2 数字字符串2
 @param methodsMode 加，减，乘，除
 @param roundingMode 舍入模式(四舍五入，只舍，只入，前一位奇入偶舍(例1.25->1.2,1.35->1.4))
 @param scale 保留几位小数
 @return NSDecimalNumber
 */
+ (NSDecimalNumber *)dd_calculateWithStr1:(NSString *)str1
                                     str2:(NSString *)str2
                              methodsMode:(DDMethodsMode)methodsMode
                             roundingMode:(NSRoundingMode)roundingMode
                                    scale:(short)scale;

+ (NSDecimalNumber *)dd_calculateWithFloatValue1:(CGFloat)floatValue1
                                     floatValue2:(CGFloat)floatValue2
                                     methodsMode:(DDMethodsMode)methodsMode
                                    roundingMode:(NSRoundingMode)roundingMode
                                           scale:(short)scale;

+ (NSDecimalNumber *)dd_calculateWithIntegerValue1:(NSInteger)integerValue1
                                     integerValue2:(NSInteger)integerValue2
                                       methodsMode:(DDMethodsMode)methodsMode
                                      roundingMode:(NSRoundingMode)roundingMode
                                             scale:(short)scale;

+ (NSDecimalNumber *)dd_calculateWithDecimalNumber1:(NSDecimalNumber *)decimalNumber1
                                  decimalNumber2:(NSDecimalNumber *)decimalNumber2
                                     methodsMode:(DDMethodsMode)methodsMode
                                    roundingMode:(NSRoundingMode)roundingMode
                                           scale:(short)scale;

+ (NSDecimalNumber *)dd_decimalNumberWithFloat:(float)value;

+ (NSDecimalNumber *)dd_decimalNumberWithFloat:(float)value scale:(short)scale;

+ (NSDecimalNumber *)dd_decimalNumberWithFloat:(float)value roundingMode:(NSRoundingMode)roundingMode scale:(short)scale;

+ (NSDecimalNumber *)dd_decimalNumberWithDouble:(double)value;

+ (NSDecimalNumber *)dd_decimalNumberWithDouble:(double)value scale:(short)scale;

+ (NSDecimalNumber *)dd_decimalNumberWithDouble:(double)value roundingMode:(NSRoundingMode)roundingMode scale:(short)scale;

- (NSDecimalNumber *)dd_decimalNumberHandler;

- (NSDecimalNumber *)dd_decimalNumberHandlerWithRoundingMode:(NSRoundingMode)roundingMode scale:(short)scale;



@end

NS_ASSUME_NONNULL_END
