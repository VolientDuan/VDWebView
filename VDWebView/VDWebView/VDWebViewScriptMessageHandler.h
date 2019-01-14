//
//  VDWebViewScriptMessageHandler.h
//  VDWebView
//
//  Created by volientDuan on 2019/1/11.
//  Copyright © 2019 volientDuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WKScriptMessageHandler.h>

@interface VDWebViewScriptMessageHandler: NSObject<WKScriptMessageHandler>
@property (nonatomic, weak)id target;
@property (nonatomic, assign)SEL sel;
@property (nonatomic, strong) NSMutableArray *scriptMessageNames;

- (instancetype)initWithTarget:(id)target selector:(SEL)selector;

@end
