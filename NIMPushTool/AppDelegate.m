//
//  AppDelegate.m
//  NIMPushTool
//
//  Created by emily on 2018/6/21.
//  Copyright © 2018 NIM. All rights reserved.
//

#import "AppDelegate.h"
#import <UserNotifications/UserNotifications.h>
#import "NTESMainViewController.h"
#import "NTESDemoConfig.h"
#import "NSString+NTES.h"
#import "NTESLoginManager.h"
#import "NTESPageContext.h"
#import "NTESNotificationAction.h"
#import "UIView+Toast.h"

@interface AppDelegate () <UNUserNotificationCenterDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self registerNIMService];
    [self registerPushService];
    self.window = ({
        UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        [window makeKeyAndVisible];
        window;
    });
    [self setupMainVC];
    return YES;
}


- (void)registerPushService {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert) completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (!granted)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication].keyWindow makeToast:@"请开启推送功能否则无法收到推送通知" duration:2.0 position:CSToastPositionCenter];
            });
        }
    }];
    [NTESNotificationAction addNotificationTextAction];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
}

- (void)registerNIMService {
    [[NIMSDKConfig sharedConfig] setShouldSyncUnreadCount:YES];
    [[NIMSDKConfig sharedConfig] setMaxAutoLoginRetryTimes:10];
    
    //appkey 是应用的标识，不同应用之间的数据（用户、消息、群组等）是完全隔离的。
    //如需打网易云信 Demo 包，请勿修改 appkey ，开发自己的应用时，请替换为自己的 appkey 。
    //并请对应更换 Demo 代码中的获取好友列表、个人信息等网易云信 SDK 未提供的接口。
    NSString *appKey        = [[NTESDemoConfig sharedConfig] appKey];
    NIMSDKOption *option    = [NIMSDKOption optionWithAppKey:appKey];
    option.apnsCername      = [[NTESDemoConfig sharedConfig] apnsCername];
    option.pkCername        = [[NTESDemoConfig sharedConfig] pkCername];
    [[NIMSDK sharedSDK] registerWithOption:option];
}

- (void)setupMainVC {
    [[NTESPageContext sharedInstance] setupMainViewController];
}

#pragma mark - Get Token
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    //成功获取 device token
    NSString *deviceString = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    deviceString = [deviceString stringByReplacingOccurrencesOfString:@" " withString:@""];
    [[NIMSDK sharedSDK] updateApnsToken:deviceToken];
    NSLog(@"NIM Push Tool deviceToken %@", deviceString);
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"fail to get apns token :%@",error);
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo{
    NSLog(@"receive remote notification:  %@", userInfo);
}


#pragma mark - UNUserNotificationCenterDelegate

//App 处于前台接收通知时
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    completionHandler(UNNotificationPresentationOptionBadge|
                      UNNotificationPresentationOptionSound|
                      UNNotificationPresentationOptionAlert);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    //处理点击或者输入 action，本示例提供回复消息的示例
    NSString* actionIdentifierStr = response.actionIdentifier;
    
    if ([response isKindOfClass:[UNTextInputNotificationResponse class]]) {
        NSString* userSayStr = [(UNTextInputNotificationResponse *)response userText];
        NSLog(@"actionid = %@\n  userSayStr = %@",actionIdentifierStr, userSayStr);
        NIMMessage *msg = [NIMMessage new];
        msg.text = userSayStr;
        NIMSession *session = [NIMSession session:[[[NIMSDK sharedSDK] loginManager] currentAccount] type:NIMSessionTypeP2P];
        [[[NIMSDK sharedSDK] chatManager] sendMessage:msg toSession:session error:nil];
    }
    
    //收到推送的请求
    UNNotificationRequest *request = response.notification.request;
    //收到推送的内容
    UNNotificationContent *content = request.content;
    if([response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        NSLog(@"收到远程通知:%@", content.userInfo);
    }
    
    if ([actionIdentifierStr isEqualToString:@"action.look"]){
        NSLog(@"actionid = %@\n",actionIdentifierStr);
    }
    
    completionHandler();
}


@end
