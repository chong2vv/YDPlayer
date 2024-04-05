//
//  YDViewController.m
//  YDPlayer
//
//  Created by wangyuandong on 10/30/2023.
//  Copyright (c) 2023 wangyuandong. All rights reserved.
//

#import "YDViewController.h"
#import "YDPlayer_Example-Swift.h"
#import <AVFoundation/AVAudioPlayer.h>

@interface YDViewController ()

@property (nonatomic, strong)YDPlayerView *player;

@end

@implementation YDViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.player = [[YDPlayerView alloc] initWithFrame:CGRectMake(0, 0, 400, 300)];
    [self.player setVideoURL:@"https://stream7.iqilu.com/10339/article/202002/17/c292033ef110de9f42d7d539fe0423cf.mp4" hasPreview:NO];
    [self.view addSubview:self.player];
    
    UIButton *playBt = [UIButton buttonWithType:UIButtonTypeCustom];
    [playBt setTitle:@"播放" forState:UIControlStateNormal];
    [playBt setTintColor:[UIColor redColor]];
    [playBt setBackgroundColor:[UIColor blackColor]];
    [playBt addTarget:self action:@selector(playVideo) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:playBt];
    playBt.frame = CGRectMake(420, 100, 50, 30);
    
}

- (void)playVideo {
    [self.player play];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
