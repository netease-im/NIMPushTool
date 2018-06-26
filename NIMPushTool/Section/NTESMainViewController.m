//
//  ViewController.m
//  NIMPushTool
//
//  Created by emily on 2018/6/13.
//  Copyright © 2018 NIM. All rights reserved.
//

#import "NTESMainViewController.h"
#import "NSString+NTES.h"
#import "NTESNotificationAction.h"
#import "NTESLoginManager.h"
#import "NTESPageContext.h"
@import MobileCoreServices;

typedef void(^NTESChooseUserIdBlock)(NSString *userId);

@interface NTESCellItem : NSObject
@property (nonatomic,copy)   NSString    *title;
@property (nonatomic,assign) SEL         action;
@end

@implementation NTESCellItem
+ (NTESCellItem *)item:(NSString *)title
                action:(SEL)action
{
    NTESCellItem *item = [[NTESCellItem alloc] init];
    item.title = title;
    item.action = action;
    return item;
}
@end

@interface NTESMainViewController ()<NIMChatManagerDelegate, NIMLoginManagerDelegate,UITableViewDelegate,UITableViewDataSource,UIImagePickerControllerDelegate>
@property (nonatomic,strong)    NSArray *items;
@property (nonatomic,copy)      NSString *userId;
@end

@implementation NTESMainViewController

- (void)dealloc {
   
    [[[NIMSDK sharedSDK] loginManager] removeDelegate:self];
    [[[NIMSDK sharedSDK] chatManager] removeDelegate:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"富文本推送 Demo";
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupDelegation];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"登出" style:UIBarButtonItemStylePlain target:self action:@selector(doLogout:)];
    
    self.items = @[[NTESCellItem item:@"发送图片" action:@selector(sendImage)],
                   [NTESCellItem item:@"发送视频" action:@selector(sendVideo)],
                   [NTESCellItem item:@"发送交fu消息" action:@selector(sendAction)]];
    [self.tableView registerClass:[UITableViewCell class]
           forCellReuseIdentifier:@"item"];
}

- (void)setupDelegation {
    [[[NIMSDK sharedSDK] loginManager] addDelegate:self];
    [[[NIMSDK sharedSDK] chatManager] addDelegate:self];
}




#pragma mark - Selector
- (void)sendImage
{
    [self chooseUserId:^(NSString *userId) {
        
        self.userId = userId;
        
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        picker.mediaTypes = @[(NSString *)kUTTypeImage];
        
        [self presentViewController:picker
                           animated:YES
                         completion:nil];
    }];
}

- (void)sendVideo
{
    [self chooseUserId:^(NSString *userId) {
        
        self.userId = userId;
        
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        picker.mediaTypes = @[(NSString *)kUTTypeMovie];
        
        [self presentViewController:picker
                           animated:YES
                         completion:nil];
    }];
}

- (void)sendAction
{
    [self chooseUserId:^(NSString *userId) {

        self.userId = userId;
        [self sendActionMsg];

    }];
}



- (void)chooseUserId:(NTESChooseUserIdBlock)completion
{
    UIAlertController *vc = [UIAlertController alertControllerWithTitle:@"输入用户名"
                                                                message:nil
                                                         preferredStyle:UIAlertControllerStyleAlert];
    [vc addTextFieldWithConfigurationHandler:nil];
    [vc addAction:[UIAlertAction actionWithTitle:@"确定"
                                           style:UIAlertActionStyleDefault
                                         handler:^(UIAlertAction * _Nonnull action) {
                                             NSString *text = vc.textFields.firstObject.text;
                                             completion(text);
                                         }]];
    [self presentViewController:vc
                       animated:YES
                     completion:nil];
                             
}


#pragma mark - 发送消息
- (void)sendMessage:(NIMMessage *)message
{
    NIMSession *session = [NIMSession session:self.userId
                                         type:NIMSessionTypeP2P];
    
    [[[NIMSDK sharedSDK] chatManager] sendMessage:message
                                        toSession:session
                                            error:nil];
    [self.view makeToast:@"消息已发送"];
}

- (void)sendImage:(UIImage *)image
{
    NIMMessage *message = [NIMMessage new];
    NIMImageObject * imageObject = [[NIMImageObject alloc] initWithImage:image];
    NIMImageOption *option  = [[NIMImageOption alloc] init];
    option.compressQuality  = 0.8;
    imageObject.option = option;
    message.messageObject = imageObject;
    
    [self sendMessage:message];
}

- (void)sendVideo:(NSString *)filepath
{
    NSString *file_path = [filepath stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    NIMMessage *message = [NIMMessage new];
    NIMVideoObject *videoObject = [[NIMVideoObject alloc] initWithSourcePath:file_path];
    message.messageObject = videoObject;
    [self sendMessage:message];
}

- (void)sendActionMsg
{
    NIMMessage *message = [NIMMessage new];
    message.text = @"hi,you";
    message.apnsPayload = @{
                            @"apsField":@{
                                    @"alert" : @{
                                            @"title" : @"iOS远程交互推送，我是主标题！-title",
                                            @"subtitle" : @"iiOS远程交互推送，我是主标题！-Subtitle",
                                            @"body" : @"正文 富文本 -body",
                                            },
                                    @"category" : @"NTES_Category",
                                    @"sound" : @"push.caf",
                                    @"mutable-content" : @"1",
                                    },
                            };
    [self sendMessage:message];
    
}

#pragma mark - Private
- (void)doLogout:(UIButton *)sender {
    [[[NIMSDK sharedSDK] loginManager] logout:^(NSError * _Nullable error) {
        NSLog(@"doLogOut : error %@", error);
        [[NTESLoginManager sharedManager] setCurrentNTESLoginData:nil];
        [[NTESPageContext sharedInstance] setupMainViewController];
    }];
}

#pragma mark - ChatManagerDelegate
//收到该回调，添加 apns 设置
- (void)uploadAttachmentSuccess:(NSString *)urlString forMessage:(NIMMessage *)message {
    NSString *mediaURL = nil;
    NSString *type = nil;
    if (message.messageType == NIMMessageTypeVideo)
    {
        type = @"video";
        mediaURL = urlString;
    }
    else
    {
        type = @"image";
        mediaURL = [[[NIMSDK sharedSDK] resourceManager] imageThumbnailURL:urlString];
    }
    message.apnsPayload = @{
                        @"apsField":@{
                                @"alert" : @{
                                        @"title" : @"NIM 远程富文本消息",
                                        @"subtitle" : @"Copyright (c) 2018, NetEase Inc.",
                                        },
                                @"category" : @"image_category",
                                @"mutable-content" : @"1",
                                },
                        @"type" : type,
                        @"media" : mediaURL,
                        };
}

- (void)sendMessage:(NIMMessage *)message didCompleteWithError:(NSError *)error
{
    NSLog(@"send %@ error %@",message,error);
}

#pragma mark - uitableview
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NTESCellItem *item = [_items objectAtIndex:[indexPath row]];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"item"];
    cell.textLabel.text = item.title;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NTESCellItem *item = [_items objectAtIndex:[indexPath row]];
    SEL selector = [item action];
    [self performSelector:selector];
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    //视频
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(NSString *)kUTTypeMovie])
    {
        NSString *filepath = [info[UIImagePickerControllerMediaURL] absoluteString];
        [self sendVideo:filepath];
    }
    else
    {
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        [self sendImage:image];
    }
    [picker dismissViewControllerAnimated:YES
                               completion:nil];
}
@end
