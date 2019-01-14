//
//  VDWebView.h
//  Common
//
//  Created by volientDuan on 2018/12/19.
//  Copyright © 2018 volientDuan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WKScriptMessageHandler.h>
#import <WebKit/WebKit.h>
#import "VDWebViewProtocol.h"
#import "VDWebViewJSBridge.h"

@class VDWebView;
@interface VDWebView : UIView<VDWebViewProtocol, VDWebViewScriptProtocol, VDWebViewCookiesProtocol>

#pragma mark - VD的基本属性和方法
@property(nonatomic, assign) id<VDWebViewDelegate> delegate;

#pragma mark - UI || WK 的API
///UI || WK 的API
@property (nonatomic, readonly) UIScrollView *scrollView;

- (id)loadRequest:(NSURLRequest *)request;
- (id)loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL;

@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly) NSURLRequest *currentRequest;
@property (nonatomic, readonly) NSURL *URL;

@property (nonatomic, readonly, getter=isLoading) BOOL loading;
@property (nonatomic, readonly) BOOL canGoBack;
@property (nonatomic, readonly) BOOL canGoForward;

- (id)goBack;
- (id)goForward;
- (id)reload;
- (id)reloadFromOrigin;
- (void)stopLoading;

@end
