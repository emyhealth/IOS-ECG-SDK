//
//  UIScreen+DDSizeTransfrom.m
//  healthCheck
//
//  Created by admin on 2019/11/29.
//  Copyright © 2019 xlf. All rights reserved.
//

#import "UIScreen+DDSizeTransfrom.h"

@implementation UIScreen (DDSizeTransfrom)

+ (CGFloat)getPerMillimetreOfPT
{
    NSInteger sc_w = [[UIScreen mainScreen] bounds].size.width;
    NSInteger sc_h = [[UIScreen mainScreen] bounds].size.height;
    
    NSInteger nativeHeight = [[UIScreen mainScreen] nativeBounds].size.height;
    
    CGFloat sc_s;
    if (nativeHeight == 480 || nativeHeight == 960) {
        sc_s = 3.5;
    } else if(nativeHeight == 1136) { //iPhone 5/5S/5C/SE
        sc_s = 4.0;
    } else if(nativeHeight == 1334) { //iPhone 6/6S/7/8
        sc_s = 4.0;
    } else if (nativeHeight== 2208) { //iPhone 6/6S/7/8 Plus
        sc_s = 5.5;
    } else if (nativeHeight== 2436) { //x xs iphone11_pro
        sc_s = 5.8;
    } else if (nativeHeight== 1792) { //xr iphone11
        sc_s = 6.1;
    } else if (nativeHeight== 2688) { //xs_max  iPhone11_Pro_Max
        sc_s = 6.5;
    } else {
        sc_s = [self getPhysicalSize]; //手动计算 有误差不准
    }
    
    //    double result11 = sqrt(sc_w * sc_w + sc_h * sc_h)/(sc_s * 25.4);//mm
    double sqrtResult = sqrt(sc_w * sc_w + sc_h * sc_h);//mm
    NSDecimalNumberHandler *handler = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundPlain scale:8 raiseOnExactness:NO raiseOnOverflow:NO raiseOnUnderflow:NO raiseOnDivideByZero:YES];
    NSDecimalNumber *scDec = [[NSDecimalNumber alloc] initWithFloat:sc_s];
    NSDecimalNumber *scaleDec = [[NSDecimalNumber alloc] initWithFloat:25.4];
    NSDecimalNumber *result1 = [scDec decimalNumberByMultiplyingBy:scaleDec withBehavior:handler];
    
    NSDecimalNumber *sqrDec = [[NSDecimalNumber alloc] initWithDouble:sqrtResult];
    NSDecimalNumberHandler *handler1 = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundPlain scale:2 raiseOnExactness:NO raiseOnOverflow:NO raiseOnUnderflow:NO raiseOnDivideByZero:YES];
    
    NSDecimalNumber *resultFinal = [sqrDec decimalNumberByDividingBy:result1 withBehavior:handler1];
    //1mm米的像素点pt
    return resultFinal.floatValue;
}

+ (CGFloat)getPhysicalSize
{
    CGFloat scale = [[UIScreen mainScreen] scale];
    NSInteger ppi = scale * ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 132 : 163);
    NSInteger width = ([[UIScreen mainScreen] bounds].size.width * scale);
    NSInteger height = ([[UIScreen mainScreen] bounds].size.height * scale);
    
    NSDecimalNumberHandler *handler = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundPlain scale:8 raiseOnExactness:NO raiseOnOverflow:NO raiseOnUnderflow:NO raiseOnDivideByZero:YES];
    
    NSDecimalNumber *ppiDec = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%ld",(long)ppi]];
    NSDecimalNumber *widthDec = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%ld",(long)width]];
    NSDecimalNumber *heightDec = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%ld",(long)height]];
    NSDecimalNumber *horizontal = [widthDec decimalNumberByDividingBy:ppiDec withBehavior:handler];
    NSDecimalNumber *vertical = [heightDec decimalNumberByDividingBy:ppiDec withBehavior:handler];
    
    NSDecimalNumber *horizontalPower = [horizontal decimalNumberByRaisingToPower:2 withBehavior:handler];
    NSDecimalNumber *verticalPower = [vertical decimalNumberByRaisingToPower:2 withBehavior:handler];
    
    CGFloat sqrtResult = sqrt([horizontalPower floatValue] + [verticalPower floatValue]);
    
    NSDecimalNumberHandler *roundingBehavior = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundPlain
                                                                                                      scale:1 raiseOnExactness:NO raiseOnOverflow:NO raiseOnUnderflow:NO raiseOnDivideByZero:NO];
    NSDecimalNumber *resultDec = [[NSDecimalNumber alloc] initWithFloat:sqrtResult];
    NSDecimalNumber *resultDN = [resultDec decimalNumberByRoundingAccordingToBehavior:roundingBehavior];
    return resultDN.doubleValue;
}

@end
