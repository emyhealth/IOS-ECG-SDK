//
//  DDECGChart.h
//  healthCheck
//
//  Created by admin on 2019/10/27.
//  Copyright © 2019 xlf. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DDECGChart : UIView

@property (nonatomic, assign)  CGFloat electricity;

@property (nonatomic, copy)  NSString *heartRateValue;

- (void)clearECG;

- (void)addECGPointWithValue:(CGFloat )value;

- (void)stopDrawECG;

- (void)pausedDisplayLink;

- (void)resumeDisplayLink;

- (void)resetContext;

@end

NS_ASSUME_NONNULL_END
