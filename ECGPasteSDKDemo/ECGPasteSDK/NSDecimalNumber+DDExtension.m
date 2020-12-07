//
//  NSDecimalNumber+DDExtension.m
//  healthCheck
//
//  Created by admin on 2019/11/14.
//  Copyright © 2019 xlf. All rights reserved.
//

#import "NSDecimalNumber+DDExtension.h"

@implementation NSDecimalNumber (DDExtension)

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
                                    scale:(short)scale
{
    NSDecimalNumber *num1 = [NSDecimalNumber decimalNumberWithString:str1];
    NSDecimalNumber *num2 = [NSDecimalNumber decimalNumberWithString:str2];
    return [self dd_calculateWithDecimalNumber1:num1 decimalNumber2:num2 methodsMode:methodsMode roundingMode:roundingMode scale:scale];
}

+ (NSDecimalNumber *)dd_calculateWithFloatValue1:(CGFloat)floatValue1
                                     floatValue2:(CGFloat)floatValue2
                                     methodsMode:(DDMethodsMode)methodsMode
                                    roundingMode:(NSRoundingMode)roundingMode
                                           scale:(short)scale
{
    NSDecimalNumber *num1 = [[NSDecimalNumber alloc] initWithFloat:floatValue1];
    NSDecimalNumber *num2 = [[NSDecimalNumber alloc] initWithFloat:floatValue2];
    return [self dd_calculateWithDecimalNumber1:num1 decimalNumber2:num2 methodsMode:methodsMode roundingMode:roundingMode scale:scale];
}

+ (NSDecimalNumber *)dd_calculateWithIntegerValue1:(NSInteger)integerValue1
                                     integerValue2:(NSInteger)integerValue2
                                       methodsMode:(DDMethodsMode)methodsMode
                                      roundingMode:(NSRoundingMode)roundingMode
                                             scale:(short)scale
{
    NSDecimalNumber *num1 = [[NSDecimalNumber alloc] initWithInteger:integerValue1];
    NSDecimalNumber *num2 = [[NSDecimalNumber alloc] initWithInteger:integerValue2];
    return [self dd_calculateWithDecimalNumber1:num1 decimalNumber2:num2 methodsMode:methodsMode roundingMode:roundingMode scale:scale];
}

+ (NSDecimalNumber *)dd_calculateWithDecimalNumber1:(NSDecimalNumber *)decimalNumber1
                                  decimalNumber2:(NSDecimalNumber *)decimalNumber2
                                     methodsMode:(DDMethodsMode)methodsMode
                                    roundingMode:(NSRoundingMode)roundingMode
                                           scale:(short)scale
{
    NSDecimalNumber *num3;
    //默认四舍五入
     NSDecimalNumberHandler *roundUp = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:roundingMode? roundingMode:NSRoundPlain scale:scale raiseOnExactness:NO raiseOnOverflow:NO raiseOnUnderflow:NO raiseOnDivideByZero:YES];

     switch (methodsMode) {
         case DDMethodsModeAddition: {
             num3 = [decimalNumber1 decimalNumberByAdding:decimalNumber2 withBehavior:roundUp];
         }
             break;
         case DDMethodsModeSubtraction: {
             num3 = [decimalNumber1 decimalNumberBySubtracting:decimalNumber2 withBehavior:roundUp];
         }
             break;
         case DDMethodsModeMultiplication: {
             num3 = [decimalNumber1 decimalNumberByMultiplyingBy:decimalNumber2 withBehavior:roundUp];
         }
             break;
         case DDMethodsModeDivision: {
             num3 = [decimalNumber1 decimalNumberByDividingBy:decimalNumber2 withBehavior:roundUp];
         }
             break;
             
         default:
             break;
     }
     
     return num3;
}

+ (NSDecimalNumber *)dd_decimalNumberWithFloat:(float)value
{
    return [self dd_decimalNumberWithFloat:value scale:2];
}

+ (NSDecimalNumber *)dd_decimalNumberWithFloat:(float)value scale:(short)scale
{
    return [self dd_decimalNumberWithFloat:value roundingMode:NSRoundBankers scale:scale];
}

+ (NSDecimalNumber *)dd_decimalNumberWithFloat:(float)value roundingMode:(NSRoundingMode)roundingMode scale:(short)scale
{
    return [[[NSDecimalNumber alloc] initWithFloat:value] dd_decimalNumberHandlerWithRoundingMode:roundingMode scale:scale];
}

+ (NSDecimalNumber *)dd_decimalNumberWithDouble:(double)value{
    return [self dd_decimalNumberWithDouble:value scale:2];
}

+ (NSDecimalNumber *)dd_decimalNumberWithDouble:(double)value scale:(short)scale{
    return [self dd_decimalNumberWithDouble:value roundingMode:NSRoundBankers scale:scale];
}

+ (NSDecimalNumber *)dd_decimalNumberWithDouble:(double)value roundingMode:(NSRoundingMode)roundingMode scale:(short)scale
{
    return [[[NSDecimalNumber alloc] initWithDouble:value] dd_decimalNumberHandlerWithRoundingMode:roundingMode scale:scale];
}

- (NSDecimalNumber *)dd_decimalNumberHandler
{
    return [self dd_decimalNumberHandlerWithRoundingMode:NSRoundPlain scale:2];
}

//
- (NSDecimalNumber *)dd_decimalNumberHandlerWithRoundingMode:(NSRoundingMode)roundingMode scale:(short)scale
{
    NSDecimalNumberHandler *handler = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:roundingMode scale:scale raiseOnExactness:NO raiseOnOverflow:NO raiseOnUnderflow:NO raiseOnDivideByZero:YES];
    
    return [self decimalNumberByRoundingAccordingToBehavior:handler];
}

@end
