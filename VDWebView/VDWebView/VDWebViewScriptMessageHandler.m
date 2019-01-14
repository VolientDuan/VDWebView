//
//  VDWebViewScriptMessageHandler.m
//  VDWebView
//
//  Created by volientDuan on 2019/1/11.
//  Copyright © 2019 volientDuan. All rights reserved.
//

#import "VDWebViewScriptMessageHandler.h"

@implementation VDWebViewScriptMessageHandler

- (NSMutableArray *)scriptMessageNames {
    if (!_scriptMessageNames) {
        _scriptMessageNames = [NSMutableArray array];
    }
    return _scriptMessageNames;
}

- (instancetype)initWithTarget:(id)target selector:(SEL)selector {
    self = [super init];
    if (self) {
        self.target = target;
        self.sel = selector;
    }
    return self;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    IMP imp = [self.target methodForSelector:self.sel];
    void (*func)(id, SEL, WKScriptMessage *) = (void *)imp;
    func(self.target,self.sel, message);
}

@end
