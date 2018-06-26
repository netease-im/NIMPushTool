//
//  NTESPageContext.h
//  VankeStreamAssistant
//
//  Created by chris on 16/3/12.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NTESPageContext : NSObject

+ (instancetype)sharedInstance;

- (void)setupMainViewController;

@end
