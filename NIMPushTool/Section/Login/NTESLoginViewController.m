//
//  NTESLoginViewController.m
//  NIMDemo
//
//  Created by ght on 15-1-26.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESLoginViewController.h"
#import <NIMSDK/NIMSDK.h>
#import "UIView+Toast.h"
#import "UIView+NTES.h"
#import "NSString+NTES.h"
#import "NTESLoginManager.h"
#import "NTESPageContext.h"

#define StatusBarHeight [[UIApplication sharedApplication] statusBarFrame].size.height
#define NavBarHeight 44.0
#define TopHeight (StatusBarHeight + NavBarHeight)

@interface NTESLoginViewController ()

@property (strong, nonatomic) IBOutlet UITextField *usernameTextField;
@property (strong, nonatomic) IBOutlet UITextField *passwordTextField;
@property (strong, nonatomic) UIImageView *nimLogo;
@property(nonatomic, strong) UIButton *loginBtn;
@end

@implementation NTESLoginViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:UITextFieldTextDidChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configNav];
    self.usernameTextField.tintColor = [UIColor lightGrayColor];
    [self.usernameTextField setValue:[UIColor lightGrayColor] forKeyPath:@"_placeholderLabel.textColor"];
    self.passwordTextField.tintColor = [UIColor lightGrayColor];
    [self.passwordTextField setValue:[UIColor lightGrayColor] forKeyPath:@"_placeholderLabel.textColor"];
    UIButton *pwdClearButton = [self.passwordTextField valueForKey:@"_clearButton"];
    [pwdClearButton setImage:[UIImage imageNamed:@"login_icon_clear"] forState:UIControlStateNormal];
    UIButton *userNameClearButton = [self.usernameTextField valueForKey:@"_clearButton"];
    [userNameClearButton setImage:[UIImage imageNamed:@"login_icon_clear"] forState:UIControlStateNormal];
    self.loginBtn.enabled = [self.usernameTextField.text length] && [self.passwordTextField.text length];
    __weak typeof(self) wself = self;
    [@[self.nimLogo,
       self.loginBtn] enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL * _Nonnull stop) {
           [wself.view addSubview:view];
       }];
}

- (void)viewDidLayoutSubviews {
    self.nimLogo.width = 112.5 ;
    self.nimLogo.height = 18;
    self.nimLogo.centerX = self.view.centerX;
    self.nimLogo.top = 40 + TopHeight;
    
    self.loginBtn.width = 303.5;
    self.loginBtn.height = 45.5;
    self.loginBtn.centerX = self.view.centerX;
    self.loginBtn.top = self.view.height - 200;
}


- (void)configNav{
    self.navigationItem.title = @"云信推送";
    NSShadow *shadow = [[NSShadow alloc]init];
    shadow.shadowOffset = CGSizeMake(0, 0);
    NSDictionary *attributes= [NSDictionary dictionaryWithObjectsAndKeys:[UIColor blackColor],NSForegroundColorAttributeName, nil];
    [self.navigationController.navigationBar setTitleTextAttributes:attributes];
}


- (void)doLogin
{
    [self.usernameTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
    
    NSString *username = [_usernameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *password = [_passwordTextField.text ntes_tokenByPassword];
    
    __weak typeof(self) wself = self;
    [[[NIMSDK sharedSDK] loginManager] login:username token:password completion:^(NSError * _Nullable error) {
        if (error == nil)
        {
            NTESLoginData *sdkData = [[NTESLoginData alloc] init];
            sdkData.account   = username;
            sdkData.token     = password;
            sdkData.pwd      = password;
            [[NTESLoginManager sharedManager] setCurrentNTESLoginData:sdkData];
            [[NTESPageContext sharedInstance] setupMainViewController];
        }
        else
        {
            NSString *toast = [NSString stringWithFormat:@"账号或密码错误"];
            [wself.view makeToast:toast duration:2.0 position:CSToastPositionCenter];
        }
    }];
}


#pragma mark - Actions

- (void)onTouchLogin:(id)sender {
    [self doLogin];
}

#pragma mark - Notification
- (void)keyboardWillShow:(NSNotification*)notification{
    NSDictionary* userInfo = [notification userInfo];
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardFrame;
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrame];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    CGFloat bottomSpacing = 10.f;
    UIView *inputView = self.passwordTextField.superview;
    if (inputView.bottom + bottomSpacing > CGRectGetMinY(keyboardFrame)) {
        CGFloat delta = inputView.bottom + bottomSpacing - CGRectGetMinY(keyboardFrame);
        inputView.bottom -= delta;
    }
    [UIView commitAnimations];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if ([string isEqualToString:@"\n"]) {
        [self doLogin];
        return NO;
    }
    return YES;
}

- (void)textFieldDidChange:(NSNotification*)notification{
    if ([self.usernameTextField.text length] && [self.passwordTextField.text length])
    {
        self.loginBtn.enabled = YES;
    }else{
        self.loginBtn.enabled = NO;
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    if ([self.usernameTextField.text length] && [self.passwordTextField.text length])
    {
        self.loginBtn.enabled = YES;
    }else{
        self.loginBtn.enabled = NO;
    }
}

#pragma mark - Private

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    [_usernameTextField resignFirstResponder];
    [_passwordTextField resignFirstResponder];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (UIImageView *)nimLogo {
    if (!_nimLogo) {
        _nimLogo = ({
            UIImageView *imgView = [UIImageView new];
            imgView.image = [UIImage imageNamed:@"login_logo"];
            imgView;
        });
    }
    return _nimLogo;
}

- (UIButton *)loginBtn {
    if (!_loginBtn) {
        _loginBtn = ({
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            [btn setBackgroundImage:[UIImage imageNamed:@"login_enter"] forState:UIControlStateNormal];
            [btn setBackgroundImage:[UIImage imageNamed:@"login_enter_disable"] forState:UIControlStateDisabled];
            btn.layer.cornerRadius = 23;
            [btn setTitle:@"登录" forState:UIControlStateNormal];
            [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            btn.enabled = NO;
            [btn addTarget:self action:@selector(onTouchLogin:) forControlEvents:UIControlEventTouchUpInside];
            btn;
        });
    }
    return _loginBtn;
}

@end
