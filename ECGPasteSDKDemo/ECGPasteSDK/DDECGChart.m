//
//  DDECGChart.m
//  healthCheck
//
//  Created by admin on 2019/10/27.
//  Copyright © 2019 xlf. All rights reserved.
//

#import "DDECGChart.h"
#import "UIScreen+DDSizeTransfrom.h"
#import "NSDecimalNumber+DDExtension.h"
#define PI 3.14159265358979323846
#define RGBA(r, g, b, a) ([UIColor colorWithRed:(r / 255.0) green:(g / 255.0) blue:(b / 255.0) alpha:a])

#define RGB(r, g, b) RGBA(r,g,b,1)

#define RGBHexColor(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
#define DDTEXTCOLOR RGBHexColor(0x444444)
@interface DDHrPotint : NSObject

@property (nonatomic, assign) CGFloat x;

@property (nonatomic, assign) CGFloat y;

@end

@implementation DDHrPotint

@end

@interface DDECGChart ()

@property (nonatomic, strong) NSMutableArray *arrayHrPoint;

@property (nonatomic, strong) NSMutableArray *arrayDrawPoint;

@property (nonatomic, assign)  BOOL isBusy;

@property (nonatomic, strong) CADisplayLink *displayLink;

@property (nonatomic, assign)  BOOL isStarted;

@property (nonatomic, assign)  CGFloat baseScale;

@property (nonatomic, strong) dispatch_source_t timer;

@end

@implementation DDECGChart

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _electricity = -1;
        _baseScale = [UIScreen getPerMillimetreOfPT];
        _arrayHrPoint = [[NSMutableArray alloc] init];
        _arrayDrawPoint = [[NSMutableArray alloc] init];
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(drawHRContext)];
        _displayLink.paused = YES;
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (void)cancelTimer
{
    if (self.timer) {
        dispatch_cancel(self.timer);
    }
    self.timer = nil;
}

- (void)startTimerIfNeed
{
    if (!_timer) {
        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        //每秒执行一次
        dispatch_source_set_timer(self.timer, dispatch_walltime(NULL, 0), 0.01 * NSEC_PER_SEC, 0);
        dispatch_source_set_event_handler(self.timer, ^{
            [self drawHRContext];
        });
        dispatch_resume(self.timer);
    }
}

- (void)setElectricity:(CGFloat)electricity
{
    _electricity = electricity;
    
    CGSize size = self.bounds.size;
    CGRect bounds = self.bounds;
    UIGraphicsBeginImageContextWithOptions(size, YES, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self drawBackground:context rect:bounds];
    [self drawBaseLine:context size:size];
    [self drawElectricity:electricity bmpValue:self.heartRateValue context:context size:size];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.layer.contents = (__bridge id)(image.CGImage);
}

- (void)setHeartRateValue:(NSString *)heartRateValue
{
    _heartRateValue = heartRateValue;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self drawBackground:context rect:rect];
    [self drawBaseLine:context size:rect.size];
    [self drawElectricity:self.electricity bmpValue:self.heartRateValue context:context size:rect.size];
}

- (void)drawBackground:(CGContextRef)context rect:(CGRect)rect
{
    //1mv = 1cm = 0.4sec = 2大格 = 10小格
    //1小格 = 0.04sec = 4 px = 4个点
    CGContextBeginPath(context);
    UIColor *bgColor = [UIColor whiteColor];// 背景色
    CGContextAddRect(context, rect);
    CGContextSetFillColorWithColor(context, bgColor.CGColor);
    CGContextFillPath(context);
    
    UIColor *slineColor = RGBHexColor(0xf0e8e9);
    CGContextSetLineWidth(context, 0.5f);//设置线的宽度
    CGContextSetStrokeColorWithColor(context, slineColor.CGColor);//设置线条颜色
    
    CGFloat width = rect.size.width;
    CGFloat height = rect.size.height;
    
    CGFloat sEach = self.baseScale;
    NSInteger sColumns = 0;
    while (sColumns * sEach < width) {
        CGContextMoveToPoint(context, sColumns*sEach + 0.5, 0);
        CGContextAddLineToPoint(context, sColumns*sEach + 0.5, width);
        sColumns++;
    }
    CGContextMoveToPoint(context, sColumns*sEach + 0.5, 0);
    CGContextAddLineToPoint(context, sColumns*sEach + 0.5, width);
    
    NSInteger sRows = 0;
    while (sRows * sEach < height) {
        CGContextMoveToPoint(context, 0, sRows*sEach + 0.5);
        CGContextAddLineToPoint(context, width, sRows*sEach + 0.5);
        sRows++;
    }
    CGContextMoveToPoint(context, 0, sRows*sEach + 0.5);
    CGContextAddLineToPoint(context, height, sRows*sEach + 0.5);
    
    CGContextStrokePath(context);
    
    UIColor *mlineColor = RGBHexColor(0xe1ced1);
    CGContextSetLineWidth(context, 0.5f);//设置线的宽度
    CGContextSetStrokeColorWithColor(context, mlineColor.CGColor);//设置线条颜色
    
    CGFloat mEach = 5 * sEach;
    NSInteger mColumns = 0;
    while (mColumns * mEach < width) {
        CGContextMoveToPoint(context, mColumns*mEach + 0.5, 0);
        CGContextAddLineToPoint(context, mColumns*mEach + 0.5, height);
        mColumns++;
    }
    
    NSInteger mRows = 0;
    while (mRows * mEach < height) {
        CGContextMoveToPoint(context, 0, mRows*mEach + 0.5);
        CGContextAddLineToPoint(context, width, mRows*mEach + 0.5);
        mRows++;
    }
    
    CGContextStrokePath(context);
    
//    UIColor *maxlineColor = [UIColor redColor];
//    CGContextSetLineWidth(context, 1.0f);//设置线的宽度
//    CGContextSetStrokeColorWithColor(context, maxlineColor.CGColor);//设置线条颜色
//
//    CGFloat maxEach = 5 * 3 * sEach;
//    NSInteger maxColumns = 0;
//    while (maxColumns * maxEach < width) {
//        CGContextMoveToPoint(context, maxColumns*maxEach + 0.5, 0);
//        CGContextAddLineToPoint(context, maxColumns*maxEach + 0.5, height);
//        maxColumns++;
//    }
//
//    NSInteger maxRows = 0;
//    while (maxRows * maxEach < width) {
//        CGContextMoveToPoint(context, 0, maxRows*maxEach + 0.5);
//        CGContextAddLineToPoint(context, width, maxRows*maxEach + 0.5);
//        maxRows++;
//    }
//    CGContextStrokePath(context);
    
    CGContextSetAllowsAntialiasing(context, YES);
}

- (void)clearECG
{
    self.heartRateValue = @"";
    [self.arrayHrPoint removeAllObjects];
    [self.arrayDrawPoint removeAllObjects];
    CGFloat temp = self.electricity;
    self.electricity = temp;
}

- (void)addECGPointWithValue:(CGFloat )value
{
    if (!self.isBusy) {
        CGSize size = self.bounds.size;
        CGFloat rValue = -value;
        rValue = rValue * 10 * self.baseScale;
        
        CGFloat Hy = size.height*0.5;
        
        //心率值正常在正负c之间
        NSDecimalNumber *yDec = [NSDecimalNumber dd_decimalNumberWithFloat:(rValue + Hy) roundingMode:NSRoundBankers scale:0];
        DDHrPotint *hrPoint = [[DDHrPotint alloc] init];
        hrPoint.x = size.width;
        hrPoint.y = [yDec floatValue];
        [self.arrayHrPoint addObject:hrPoint];
    }
    
    if (!self.isStarted) {
        self.isStarted = YES;
//        [self startDisplayLink];
        [self startTimerIfNeed];
    }
}

- (void)startDisplayLink
{
    if (self.displayLink == nil) {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(drawHRContext)];
        _displayLink.paused = YES;
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
    
    if (self.displayLink.paused) {
        self.displayLink.paused = NO;
    }
}

- (void)resumeDisplayLink
{
//    self.displayLink.paused = NO;
    [self startTimerIfNeed];
}

- (void)pausedDisplayLink
{
//    self.displayLink.paused = YES;
    [self cancelTimer];
}

- (void)stopDrawECG
{
    self.isStarted = NO;
//    self.displayLink.paused = YES;
//    [self.displayLink invalidate];
//    self.displayLink = nil;
    
    [self cancelTimer];
}

- (void)resetContext
{
    [self stopDrawECG];
    [self clearECG];
}

- (void)drawHRContext
{
    if (self.arrayHrPoint.count > 0) {
        CGSize size = self.bounds.size;
        CGRect bounds = self.bounds;
        
        UIGraphicsBeginImageContextWithOptions(size, YES, [UIScreen mainScreen].scale);
        CGContextRef context = UIGraphicsGetCurrentContext();

        [self drawBackground:context rect:bounds];
        [self drawBaseLine:context size:size];
        [self drawElectricity:self.electricity bmpValue:self.heartRateValue context:context size:size];
//        CGImageRef imageRef = CGImageRetain(self.backgroundImage.CGImage);
//        CGContextDrawImage(context, bounds, imageRef);
        
        if (self.arrayHrPoint.count > 0) {
            [self.arrayDrawPoint addObject:[self.arrayHrPoint firstObject]];
            [self.arrayHrPoint removeObjectAtIndex:0];
            if (self.arrayDrawPoint.count > 600) {
                [self.arrayDrawPoint removeObjectAtIndex:0];
            }
            
            [self draw:context size:size];
            
            if(self.arrayHrPoint.count > 300) {
                self.isBusy = YES;
            }
            if (self.arrayHrPoint.count < 6) {
                self.isBusy = NO;
            }
        }
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        self.layer.contentsScale = [[UIScreen mainScreen] scale];
        self.layer.contents = (__bridge id)(image.CGImage);
    } else {
        self.isBusy = NO;
    }
}

- (void)draw:(CGContextRef)context size:(CGSize)size
{
    UIColor *lineColor = RGBHexColor(0xc97780);//设置线的颜色。
    CGContextSaveGState(context);
    CGContextSetLineWidth(context, 1.0f);//设置线的宽度
    CGContextSetStrokeColorWithColor(context, lineColor.CGColor);//设置线条颜色
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    DDHrPotint *hrPoint1 = [self.arrayDrawPoint objectAtIndex:0];
    [path moveToPoint:CGPointMake(hrPoint1.x, hrPoint1.y)];
    hrPoint1.x -= self.baseScale/4;
    for (int i = 1; i < self.arrayDrawPoint.count; i++) {
        DDHrPotint *hrPoint2 = [self.arrayDrawPoint objectAtIndex:i];
        [path addLineToPoint:CGPointMake(hrPoint2.x, hrPoint2.y)];
        [path moveToPoint:CGPointMake(hrPoint2.x, hrPoint2.y)];
        hrPoint2.x -= self.baseScale/4;
    }
    
    [path stroke];
    CGContextAddPath(context, path.CGPath);
    CGContextDrawPath(context, kCGPathStroke);
    CGContextRestoreGState(context);
}

- (void)drawBaseLine:(CGContextRef)context size:(CGSize)size
{
    CGFloat scale = self.baseScale;
    CGFloat height = size.height;

    UIColor *lineColor = [UIColor blackColor];//设置线的颜色。
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGContextSaveGState(context);
    CGContextSetStrokeColorWithColor(context, lineColor.CGColor);//设置线条颜色
    CGContextSetLineWidth(context, 0.5);//设置线的宽度
    
    CGFloat startX = scale * 3;
    CGFloat startY = height/2.0;
    
    [path moveToPoint:CGPointMake(startX, startY)];
    [path addLineToPoint:CGPointMake(startX + scale * 2, height/2.0)];
    [path moveToPoint:CGPointMake(startX + scale * 2, height/2.0)];
    [path addLineToPoint:CGPointMake(startX + scale * 2, height/2.0 - scale * 5 )];
    [path moveToPoint:CGPointMake(startX + scale * 2, height/2.0 - scale * 5 )];
    [path addLineToPoint:CGPointMake(startX + scale * 5, height/2.0 - scale * 5 )];
    [path moveToPoint:CGPointMake(startX + scale * 5, height/2.0 - scale * 5 )];
    [path addLineToPoint:CGPointMake(startX + scale * 5, height/2.0)];
    [path moveToPoint:CGPointMake(startX + scale * 5, height/2.0)];
    [path addLineToPoint:CGPointMake(startX + scale * 7, height/2.0)];
    [path moveToPoint:CGPointMake(startX + scale * 7, height/2.0)];
    
    [path stroke];
    CGContextAddPath(context, path.CGPath);
    CGContextDrawPath(context, kCGPathStroke);
    CGContextRestoreGState(context);
}

- (void)drawElectricity:(CGFloat)electricity  bmpValue:(NSString *)bmpValue context:(CGContextRef)context size:(CGSize)size
{
    UIColor *color = RGBHexColor(0xe03d43);
    CGContextSaveGState(context);
//    CGContextSetAllowsAntialiasing(context,true);//是否消除锯齿
//    CGContextSetLineCap(context, kCGLineCapRound);
//    CGContextSetLineJoin(context, kCGLineJoinRound);
    CGContextSetStrokeColorWithColor(context, color.CGColor);//画笔线的颜色
    CGContextSetLineWidth(context, 1.0);//线的宽度
    //void CGContextAddArc(CGContextRef c,CGFloat x, CGFloat y,CGFloat radius,CGFloat startAngle,CGFloat endAngle, int clockwise)1弧度＝180°/π （≈57.3°） 度＝弧度×180°/π 360°＝360×π/180 ＝2π 弧度
    // x,y为圆点坐标，radius半径，startAngle为开始的弧度，endAngle为 结束的弧度，clockwise 0为顺时针，1为逆时针。
    
    CGFloat offset = 50;
    if (bmpValue.length > 0) {
        offset = 0;
        CGContextAddArc(context, size.width - 39.5, 34, 27, 0, 2 * PI, 0);
        CGContextDrawPath(context, kCGPathStroke);
        
        NSDictionary *xlvdic = [self createStyle:12.0 color:color];
        [bmpValue drawInRect:CGRectMake(size.width - 61.5, 24, 45, 13) withAttributes:xlvdic];
        
        NSDictionary *xldic = [self createStyle:12.0 color:DDTEXTCOLOR];
        [@"心率" drawInRect:CGRectMake(size.width - 51, 40, 25, 13) withAttributes:xldic];
    }

    if (electricity >= 0) {
        CGContextAddArc(context, size.width - 34, 87 - offset, 22, 0, 2 * PI, 0); //添加一个圆
        CGContextDrawPath(context, kCGPathStroke); //绘制路径
        NSString *string = [NSString stringWithFormat:@"%ld%%", (long)(electricity * 100)];
        NSDictionary *elecDic = [self createStyle:13.0 color:color];
        [string drawInRect:CGRectMake(size.width - 51, 75  - offset, 35, 13.5) withAttributes:elecDic];
        
        NSDictionary *dlTextDic = [self createStyle:10.0 color:DDTEXTCOLOR];
        [@"电量" drawInRect:CGRectMake(size.width - 45.5, 91 - offset, 25, 12) withAttributes:dlTextDic];
    }
    
    NSDictionary *btmTextDic = [self createStyle:11 color:DDTEXTCOLOR];
    [@"10mm/mV 25mm/s" drawInRect:CGRectMake(size.width - 120, size.height - 20, 120, 12) withAttributes:btmTextDic];
    CGContextRestoreGState(context);
}

- (NSDictionary *)createStyle:(CGFloat)fontSize color:(UIColor *)color
{
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    style.lineBreakMode =NSLineBreakByCharWrapping;
    style.alignment = NSTextAlignmentCenter;
    NSDictionary *dic=@{NSFontAttributeName:[UIFont systemFontOfSize:fontSize],
                         NSParagraphStyleAttributeName:style,
                         NSForegroundColorAttributeName:color};
    return dic;
}

@end

