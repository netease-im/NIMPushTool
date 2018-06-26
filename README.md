# NIM 富文本推送能力以及 UserNotifications Framework 简介

### 本文目的
本文旨在介绍富文本推送的基本能力以及云信 NIM SDK 对应的 Demo 进行富文本推送的应用场景。

iOS 端推送基本分为本地推送以及远程推送；本地推送通过 App 本地定制，加入到系统的 Schedule 里，在指定的时间推送指定的内容；而远程推送通过服务端向苹果推送服务器 APNs (Apple Push Notification service) 发送 Notification Payload，然后 APNs 再将推送发送到指定设备的指定 App 上。
【注】本文着重介绍推送框架的使用，关于推送证书的配置请参考其他相关文章介绍。

#### 基础配置
iOS 10 之后提供了更多更为丰富的推送设置，例如富文本推送，下文会首先介绍推送配置的基本流程，再进行一些高阶操作的介绍。
##### 导入头文件
根据工程需要，在适当的位置添加头文件
 
```objc
#import <UserNotifications/UserNotifications.h>
```
 示例里直接添加在 `AppDelegate.m` 文件
##### 推送服务注册
在 `AppDelegate.m` 的 `- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;`回调里进行推送的注册。
具体注册方式在 iOS 10 之后有更新，因此如果需要支持 iOS 10 之前的版本，需要做一个版本的判断，示例代码如下：

```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    if (@available (iOS 10.0, *)) {
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
    }
    else {
        UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types
                                                                                 categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    }
    //最后加上注册
    [[UIApplication sharedApplication] registerForRemoteNotifications];

}
```
##### 推送日志打印
在注册推送服务中可以加上获取详细推送服务设置，这样可以方便排查问题。

```objc
[center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        NSLog(@"%@",settings);
}];
```


##### 推送内容定制
iOS 10 以前只能展示一条文字，现在可以有 title、subtitle和body。
定制方法如下：

```objc
//推送设置
{
  "aps":{
        "alert" : {
             "title" : "iOS 远程消息，设置主标题！-title",
              "subtitle" : "iOS 远程消息，设置副标题！-Subtitle",
              "body" : "iOS 远程消息，设置正文 -body"
            },
        "sound" : "default",
        //...
    },
    //...
}
```
##### 推送触发器 Triggers
这也是一个 iOS 10 新推出的特性，共有四类 Trigger
其中以下三个用于出发本地推送，通过定义 Trigger 和 Content 向 UNUserNotificationCenter 进行推送的发送。
* UNTimeIntervalNotificationTrigger
* UNCalendarNotificationTrigger
* UNLocationNotificationTrigger
`UNPushNotificationTrigger`则用于远程推送，根据此可以区分推送的类型。


##### 推送的修改更新
通过 `addNotificationRequest:` 方法，在推送的 identifier 不变的情况下，可以刷新原有的推送。

#### 2）推送高级功能

##### 配置推送交互
iOS 10之后，允许推送添加交互操作 `action`，这些交互赋予应用在前台或者后台执行一些逻辑代码，并且在锁屏界面通过 3D-touch 触发。例如可以回复别人的消息。（Actions 是在 iOS 8 引入的新特性，快捷回复类型的 action 在 iOS 9 引入，iOS 10 将这些 API 统一封装）
在 iOS 10 中，这个交互功能称为 `Category`，通过 3D-Touch 触发。
###### 1）创建 `action`
一个 action 即一项交互操作，例如发送消息，创建代码示例如下：

```objc
UNTextInputNotificationAction *inputAction = [UNTextInputNotificationAction actionWithIdentifier:@"action.input" title:@"输入" options:UNNotificationActionOptionForeground textInputButtonTitle:@"发送" textInputPlaceholder:@"写下你的回复"];
```
###### 2）创建 `category`
一个 category 包含多个 action，类似一个 actionsheet 的多个操作，其中的 intentIdentifiers 填写想要添加到的推送消息 id。
###### 3）添加 category 到通知中心
```objc
[center setNotificationCategories:[NSSet setWithObject:notifyCategory]];
```

###### 4) 触发方式配置
配置发送的 category 类型为：

```objc
{
  "aps":{
        "alert" : {
             "title" : "iOS 远程消息，设置主标题！-title",
              "subtitle" : "iOS 远程消息，设置副标题！-Subtitle",
              "body" : "iOS 远程消息，设置正文 -body"
            },
        "sound" : "default",
        "category" : "xxxcategory" //自定义的 category 类型

        //...
    },
    //...
}
```
同时，创建 content 时，指定 category id 即可。

```objc
content.categoryIdentifier = @"xxxcategory";
```

###### 5）交互结果处理

用户点击这些 actions 之后，是触发键盘、启动 App、清除通知或者是其他响应，这些全部需要实现协议 UNUserNotificationCenterDelegate 中的相关代理即可实现，代理代码如下：

```objc
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler;
```

其中 resonse 包含以下内容：

![response.png](https://i.loli.net/2018/06/13/5b20b284e3ddb.png)

举例一段处理回复消息的 response 处理代码：

```objc
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    NSString *categoryIdentifier = response.notification.request.content.categoryIdentifier;

    if ([categoryIdentifier isEqualToString:@""]) {//识别需要被处理的拓展

        if ([response.actionIdentifier isEqualToString:@""]) {//识别用户点击的是哪个 action

            //假设点击了输入内容的 UNTextInputNotificationAction 把 response 强转类型
            UNTextInputNotificationResponse *textResponse = (UNTextInputNotificationResponse*)response;
            //获取输入内容
            NSString *userText = textResponse.userText;
            //发送 userText 给需要接收的方法
            [ClassName handleUserText: userText];
        }
    }
    completionHandler();
}
```
#### 富文本
iOS 10 推出 Service Extension 扩展，通过在客户端对接收到的内容进行加工，适配 iOS 10 的展示效果。原理即在该扩展里你获得了一小段在后台运行代码的时间，可以给推送添加附件（比如音乐、图片），从而使推送更为丰富，并且，如果推送更改失败，仍然会展示最初收到的推送内容。
首先介绍配置方式：

##### 更新推送方式
1） 添加 Service Extension
在 Xcode 工程添加 File -> New -> Target 如下图所示：

![](https://s1.ax1x.com/2018/06/13/COaJ5F.png)

添加后会自动创建一个 UNNotificationServiceExtension 的子类 NotificationService，通过完善这个子类，进行需求扩展。

```objc
- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    self.contentHandler = contentHandler;
    self.bestAttemptContent = [request.content mutableCopy];
    
    // Modify the notification content here...
    
    self.contentHandler(self.bestAttemptContent);

}

- (void)serviceExtensionTimeWillExpire {
    // Called just before the extension will be terminated by the system.
    // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
    self.contentHandler(self.bestAttemptContent);
}
```
* didReceiveNotificationRequest 让你可以在后台处理接收到的推送，传递最终的内容给 contentHandler
* serviceExtensionTimeWillExpire 在你获得的一小段运行代码的时间即将结束的时候，如果仍然没有成功的传入内容，会走到这个方法，可以在这里传肯定不会出错的内容，否则会默认传递原始的推送内容。

2）修改推送

```objc
{
  "aps":{
        "alert" : {
             "title" : "iOS远程消息，我是主标题！-title",
              "subtitle" : "iOS远程消息，我是主标题！-Subtitle",
              "body" : "Dely,why am i so handsome -body"
            },
        "mutable-content" : "1",
    },
    customAttachment : "https://p1.bpimg.com/524586/475bc82ff016054ds.jpg",
}
```
* 首先需要添加 mutable-content : 1，这意味着此条推送可以被 Service Extension 进行更改；
* customAttachment 是自定义字段，key 可以自定义，value 是完整的文件名，即要展示的内容；
* 各种 media 文件大小有一定限制，图片、视频等过大都不会被展示，Apple 的意思是：对于图片，最大宽度也就和屏幕等宽，过大的图片没有意义；对于音频、视频等，完全可以提供一个短时间预览部分，更多的内容还是需要用户点击推送进入 App 之后对完整的内容进行查看。
具体添加一个图片的例子如下：

```objc
//apns 添加
    "image" : "https://p1.bpimg.com/524586/475bc82ff016054ds.jpg"
    //这里给一个示例图床链接
```

```objc
- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    self.contentHandler = contentHandler;
    self.bestAttemptContent = [request.content mutableCopy];
    
    // Modify the notification content here...
    self.bestAttemptContent.title = [NSString stringWithFormat:@"%@ [modified]", self.bestAttemptContent.title];
    
    NSString *imgAttachUrl = [request.content.userInfo objectForKey:@"image"];
    
    //下载图片放到本地
    UIImage *img = [self getImageUrlFrom:imgAttachUrl];
    
    NSString *imgPath = [self saveImage:img withFileName:@"pushImage" ofType:@"png"];
    
    if (imgPath && ![imgPath isEqualToString:@""]) {
        UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:@"photo" URL:[NSURL URLWithString:[@"file://" stringByAppendingString:imgPath]] options:nil error:nil];
        if (attachment) {
            //塞到回调里
            self.bestAttemptContent.attachments = @[attachment];
        }
    }
    
    self.contentHandler(self.bestAttemptContent);

}
```
【注】在示例代码内还实现了视频的远程推送，具体代码见工程，这里不再赘述。
##### 自定义推送界面布局
现有的默认推送布局包括横屏、锁屏、通知中心三处，排版都类似。
推送界面添加图片、视频都可以在上面三个界面通过3D-Touch 触发。如下图：
![](https://upload-images.jianshu.io/upload_images/1944178-4c1e7ae1c5744115.gif?imageMogr2/auto-orient/strip%7CimageView2/2/w/350)
自定义布局的功能即可以把需要推送的内容（比如一条完整的新闻快讯，包括多条文字+图片的组合）全部放到一条推送里，用户点击了一个 Action（如赞、关注、评论等），在推送里立刻刷新 UI（如展示加星动画、评论内容等）。

1）添加方法
打开 iOS Xcode Project - File - New - Target - iOS - Notification Content - Next - Product Name 填写 yourPushNotificationContent - Finish

系统会在 Xcode 工程目录中 自动生成 yourPushNotificationContent 文件夹，并且包含四个文件：NotificationViewController.h、NotificationViewController.m、MainInterface.storyboard、Info.plist。
###### NotificationViewController.h/m
* 继承自 UIViewController，并实现了 UNNotificationContentExtension 协议。
* 在 viewDidLoad 里各种代码写你的 UI，或者使用 storyboard 拖拖拽拽就 ok。
* 在 didReceiveNotification 方法里接收推送内容，然后各种处理逻辑、传值、展示 UI 等等。当点击了 actions，也会走到这里，并且包含一个 action 的字段，判断点击了哪个 action 进而相应的更新你的 UI。

###### info.plist
需要在这个字段里让系统知道，哪个 ID 字段会触发 extension
![](https://s1.ax1x.com/2018/06/13/COaBb6.png)

这个字段的值，必须和 Notification Actions 的 category id 值一样，这样收到推送时，就会同时触发 Notification content + Notification actions。
2）自定义界面
自定义界面时会发现系统会自动展示一遍收到的推送内容，这很可能和你的内容有重复，通过添加如下字段可以隐藏系统默认：
3）界面尺寸自定义
自定义推送时会发现，展示内容较少时，系统仍然以最大的界面展示出来，会露出很多空白，有两个方式进行修改：

```objc
- (void)viewdidLoad {
    [super viewdidLoad];
    CGSize size = self.view.bounds.size;
    self.preferredContentSize = CGSizeMake(size.width, size.height/2);
}
```
同时，plist 添加字段，修改推送的默认高度如下：
![](https://s1.ax1x.com/2018/06/13/COacPe.png)
实现了高度的适配。

#### 富文本和云信消息的结合
关于富文本推送的介绍已经介绍完毕，在具体和云信 IM 能力场景的结合中，如果有发送云信消息的同时需要发送一条带视频或者图片的消息，并在推送中展示这个视频或者图片这样的需求场景，则需要继续添加进行如下配置：
* 构造一条消息

```objc
    NIMMessage *message = [NIMMessage new];
    NIMImageObject * imageObject = [[NIMImageObject alloc] initWithImage:image];
    NIMImageOption *option  = [[NIMImageOption alloc] init];
    option.compressQuality  = 0.8;
    imageObject.option = option;
    message.messageObject = imageObject;
```
2)在 chatManager 的 `uploadAttachmentSuccess:forMessage:` 回调里获取上传图片对应的 nos 图床链接地址，并填充 NIMMessage 的 message.apnsPayload，由云信服务器去解析该字段，并最终推送给 APNs 服务。

```objc
#pragma mark - ChatManagerDelegate
//收到该回调，添加 apns 设置
- (void)uploadAttachmentSuccess:(NSString *)urlString forMessage:(NIMMessage *)message {
    
    NSString *thumbnailURL = nil;
    NSString *type = nil;
    if (message.messageType == NIMMessageTypeVideo)
    {
        type = @"video";
    }
    else
    {
        type = @"image";
    }
    message.apnsPayload = @{
                        @"apsField":@{
                                @"alert" : @{
                                        @"title" : @"NIM 远程富文本消息",
                                        @"subtitle" : @"Copyright (c) 2018, NetEase Inc.",
                                        },
                                @"category" : @"xxx_category",
                                @"mutable-content" : @"1",
                                },
                        @"type" : type,
                        @"media" : urlString,
                        };
}
```

