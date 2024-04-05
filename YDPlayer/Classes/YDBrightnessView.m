//
//  YDBrightnessView.m
//  YDPlayer
//
//  Created by 王远东 on 2023/10/31.
//  Copyright © 2023 wangyuandong. All rights reserved.
//

#import "YDBrightnessView.h"
#import <YDUtilKit/YDUtilKit.h>

@interface YDBrightnessView ()
@property (nonatomic, strong) UIView *levelView;
@property (nonatomic, strong) NSTimer *disappearTimer;
@property (nonatomic, assign) BOOL willDisappear;
@property (nonatomic, weak) id applicationDidChangeStatusBarOrientationObserver;
@property (nonatomic, strong) YDKeyValueObserver *mainScreenBrightnessObserver;

@end

@implementation YDBrightnessView

// Frameworks bundle file
#ifndef YDToolboxFrameworkBundleFile
#define YDToolboxFrameworkBundleFile(bundle, file) [[NSBundle mainBundle] pathForResource:file ofType:nil inDirectory:[NSString stringWithFormat:@"Frameworks/YDPlayer.framework/%@", bundle]]
#endif

// Bundle file
#ifndef YDToolboxBundleFile
#define YDToolboxBundleFile(bundle, file) ([[NSBundle mainBundle] pathForResource:file ofType:nil inDirectory:bundle] ?: YDToolboxFrameworkBundleFile(bundle, file))
#endif
#define YDBrightnessBounds  CGRectMake(0.0, 0.0, 155.0, 155.0)
#define YDBrightnessColor   [UIColor colorWithHexString:@"484848" alpha:1]

+ (instancetype)brightnessView {
    static YDBrightnessView *brightnessView;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        brightnessView = [[YDBrightnessView alloc] initWithFrame:YDBrightnessBounds];
    });
    return brightnessView;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = nil;
        self.layer.cornerRadius  = 8;
        self.layer.masksToBounds = YES;
        //
        UIToolbar *toolBar = [[UIToolbar alloc] initWithFrame:self.bounds];
        toolBar.alpha = 0.99;
        [self addSubview:toolBar];
        //
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, self.bounds.size.width, 30)];
        label.font = [UIFont boldSystemFontOfSize:16];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = YDBrightnessColor;
        label.text = @"亮度";
        [self addSubview:label];
        //
        NSString *file = YDToolboxBundleFile(@"YDBrightnessView.bundle", @"brightness@2x.png");
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 75, 75)];
        imageView.image = [UIImage imageWithContentsOfFile:file];
        imageView.contentMode = UIViewContentModeScaleToFill;
        imageView.clipsToBounds = YES;
        imageView.center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
        [self addSubview:imageView];
        //
        self.levelView = [[UIView alloc] initWithFrame:CGRectMake(13, self.bounds.size.height - 16 - 7, self.bounds.size.width - 13 * 2, 7)];
        self.levelView.backgroundColor = YDBrightnessColor;
        [self addSubview:self.levelView];
        //
        CGFloat width = (self.levelView.bounds.size.width - 17) / 16;
        CGFloat height = self.levelView.bounds.size.height - 2;
        CGRect frame = CGRectMake(1, 1, width, height);
        for (NSInteger i = 0; i < 16; ++i) {
            frame.origin.x = i * (width + 1) + 1;
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
            imageView.backgroundColor = [UIColor whiteColor];
            imageView.tag = i;
            [self.levelView addSubview:imageView];
        }
        //
        _mainScreenBrightnessObserver = [[YDKeyValueObserver alloc] init];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    //
    self.bounds = YDBrightnessBounds;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
            self.center = CGPointMake(self.window.bounds.size.width / 2, (self.window.bounds.size.height - 10) / 2);
            break;
        default:
            self.center = CGPointMake(self.window.bounds.size.width / 2, self.window.bounds.size.height / 2);
            break;
    }
}

#pragma mark Brightness

- (CGFloat)brightness {
    return [UIScreen mainScreen].brightness;
}

- (void)setBrightness:(CGFloat)brightness {
    [UIScreen mainScreen].brightness = brightness;
}

#pragma mark Observer

- (void)addObserver {
    [self removeObserver];
    //
    __weak typeof(self) weakSelf = self;
    _applicationDidChangeStatusBarOrientationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidChangeStatusBarOrientationNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        [weakSelf setNeedsLayout];
    }];
    //
    [_mainScreenBrightnessObserver observe:[UIScreen mainScreen] keyPath:@"brightness" options:NSKeyValueObservingOptionNew context:NULL changeHandler:^(NSDictionary<NSKeyValueChangeKey,id> * _Nullable change, void * _Nullable context) {
        CGFloat level = [change[NSKeyValueChangeNewKey] floatValue];
        [weakSelf presentViewAnimated];
        [weakSelf updateBrightnessLevel:level];
    }];
}

- (void)removeObserver {
    if (_applicationDidChangeStatusBarOrientationObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:_applicationDidChangeStatusBarOrientationObserver];
    }
    [_mainScreenBrightnessObserver invalidate];
}

#pragma mark Present

- (void)presentViewAnimated {
    if (self.superview != self.window) {
        [self presentView];
        self.disappearTimer = [NSTimer timerWithTimeInterval:2.0
                                                      target:self
                                                    selector:@selector(dismissViewAnimated)
                                                    userInfo:nil
                                                     repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.disappearTimer forMode:NSDefaultRunLoopMode];
    } else {
        self.alpha = 1.0;
        self.willDisappear = NO;
    }
}

- (void)presentView {
    self.alpha = 1.0;
    [self.window addSubview:self];
    self.willDisappear = YES;
}

#pragma mark Dismiss

- (void)dismissViewAnimated {
    if (self.willDisappear) {
        [UIView animateWithDuration:0.3 animations:^{
            self.alpha = 0.0;
        } completion:^(BOOL finished) {
            if (self.willDisappear) {
                [self dismissView];
            }
        }];
    } else {
        self.willDisappear = YES;
    }
}

- (void)dismissView {
    [self removeFromSuperview];
    if (self.disappearTimer) {
        [self.disappearTimer invalidate];
        self.disappearTimer = nil;
    }
    self.willDisappear = NO;
}

#pragma mark Update

- (void)updateBrightnessLevel:(CGFloat)brightness {
    CGFloat stage = 1 / 15.0;
    NSInteger level = brightness / stage;
    for (UIView *view in self.levelView.subviews) {
        if ([view isKindOfClass:[UIImageView class]]) {
            view.hidden = view.tag > level;
        }
    }
}

#pragma mark Window

- (UIWindow *)window {
    return [[UIApplication sharedApplication] keyWindow];
}

@end
