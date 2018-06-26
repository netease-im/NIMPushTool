//
//  NIMNotificationAction.m
//  NIMPushTool
//
//  Created by emily on 2018/6/13.
//  Copyright © 2018 NIM. All rights reserved.
//

#import "NTESNotificationAction.h"
#import <UserNotifications/UserNotifications.h>

@implementation NTESNotificationAction

+ (void)addNotificationTextAction {
    UNTextInputNotificationAction *inputAction = [UNTextInputNotificationAction actionWithIdentifier:@"action.input" title:@"输入" options:UNNotificationActionOptionForeground textInputButtonTitle:@"发送" textInputPlaceholder:@"写下你的回复"];
    UNNotificationCategory *notifyCategory = [UNNotificationCategory categoryWithIdentifier:@"NTES_Category" actions:@[inputAction] intentIdentifiers:@[] options:UNNotificationCategoryOptionCustomDismissAction];
    
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center setNotificationCategories:[NSSet setWithObject:notifyCategory]];
}

@end
