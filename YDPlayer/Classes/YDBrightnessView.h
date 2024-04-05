//
//  YDBrightnessView.h
//  YDPlayer
//
//  Created by 王远东 on 2023/10/31.
//  Copyright © 2023 wangyuandong. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YDBrightnessView : UIView
@property (nonatomic, assign) CGFloat brightness;

+ (instancetype)brightnessView;

- (void)addObserver;
- (void)removeObserver;

- (void)presentView;
- (void)dismissView;

@end

NS_ASSUME_NONNULL_END
