//
//  VDWebViewJSBridge.h
//  VDWebView
//
//  Created by volientDuan on 2019/1/11.
//  Copyright © 2019 volientDuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VDWebView.h"

/**
 js与原生交互的桥;
 调用原生方法的原理：通过拦截请求，对URL进行解析获取方法名和参数值
 调用js方法原理：使用的是VDWebView的evaluateJavaScript方法即WKWebView所提供的方法 (iOS8.0以后)
 */
@interface VDWebViewJSBridge : NSObject
@property (nonatomic, strong)NSString *scheme;
@property (nonatomic, weak)VDWebView *webView;
@property (nonatomic, weak)id<VDWebViewDelegate> delegate;
/**
 初始化桥，在webView的代理对象绑定后初始化桥，否则会造成桥无法搭建成功

 @param webView webView
 @param delegate 代理对象
 @return bridge
 */
- (instancetype)initWithWebView:(VDWebView *)webView delegate:(id<VDWebViewDelegate>)delegate;

- (void)executeJsMethod:(NSString *)method params:(NSArray <NSString *>*)params completionHandler:(void (^)(id result, NSError *error))completionHandler;

/**
 绑定方法 - (调用此方法后将只监听绑定的方法)

 @param method 方法名
 */
- (void)bindMethod:(NSString *)method;

/**
 移除方法

 @param method 方法名
 */
- (void)removeMethod:(NSString *)method;

/**
 移除所有方法 (默认监听所有方法，只需要在代理对象中实现对应的OC方法)
 */
- (void)removeAllMethod;

@end
