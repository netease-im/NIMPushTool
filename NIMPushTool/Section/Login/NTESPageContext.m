//
//  NTESPageContex.m
//  VankeStreamAssistant
//
//  Created by chris on 16/3/12.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESPageContext.h"
#import "NTESLoginManager.h"
#import "NTESLoginViewController.h"
#import "NTESMainViewController.h"

@interface NTESPageContext()

@end

@implementation NTESPageContext

+ (instancetype)sharedInstance
{
    static NTESPageContext *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NTESPageContext alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    return self;
}

- (void)setupMainViewController
{
    NTESLoginData *data = [[NTESLoginManager sharedManager] currentNTESLoginData];
    NSString *account = [data account];
    NSString *token   = [data token];
    UIViewController *vc;
    if ([account length] && [token length])
    {
        vc = [[NTESMainViewController alloc] initWithNibName:nil bundle:nil];
        NIMAutoLoginData *loginData = [[NIMAutoLoginData alloc] init];
        loginData.account = account;
        loginData.token = token;
        loginData.forcedMode = YES;
        
        [[[NIMSDK sharedSDK] loginManager] autoLogin:loginData];
    }
    else
    {
        vc = [[NTESLoginViewController alloc] initWithNibName:nil bundle:nil];
    }
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [UIApplication sharedApplication].keyWindow.rootViewController = nav;
}

@end
