//
//  VDWebViewProtocol.h
//  VDWebView
//
//  Created by volientDuan on 2019/1/11.
//  Copyright © 2019 volientDuan. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, VDJSAlertType) {
    VDJSAlertTypeAlert = 0,
    VDJSAlertTypeConfirm,
    VDJSAlertTypePrompt
};

@class VDWebView;
@class VDWebViewJSBridge;
@class VDWebViewScriptMessageHandler;
/**
 常用方法和属性
 */
@protocol VDWebViewProtocol <NSObject>
///内部使用的webView
@property (nonatomic, readonly) WKWebView *realWebView;
@property (nonatomic, readonly) NSURLRequest *originRequest;
///预估网页加载进度
@property (nonatomic, readonly) CGFloat estimatedProgress;
// 是否显示进度条 默认不显示
@property (nonatomic, assign) BOOL isShowProgressBar;
///进度条
@property (nonatomic, strong) UIView *progressBar;
///back 层数
- (NSInteger)countOfHistory;
- (void)gobackWithStep:(NSInteger)step;
///是否根据视图大小来缩放页面  默认为NO
@property (nonatomic) BOOL scalesPageToFit;
/// web页面加载完毕后的内容高度(在页面加载完成后获取)
@property (nonatomic, readonly) CGFloat contentHeight;
/// 是否启用js调用原生弹框 默认为NO 禁止(默认加载弹框在根试图)
@property (nonatomic, assign) BOOL enableAllAlert;
@property (nonatomic, assign) BOOL enableAlert;
@property (nonatomic, assign) BOOL enableConfirm;
@property (nonatomic, assign) BOOL enablePrompt;

- (VDWebViewJSBridge *)bridgeInitialized;
@property (nonatomic, strong, readonly) VDWebViewJSBridge *bridge;

@end

/**
 script相关方法
 */
@protocol VDWebViewScriptProtocol <NSObject>
/**
 *  添加js回调oc通知方式
 *  关于js调用说明：JS通过window.webkit.messageHandlers.<OC方法名>.postMessage(<参数>) 调用OC方法 其中方法名和参数为必填项
 * 关于回调的说明：如果实现了相应的代理方法(webView:didReceiveScriptMessage:)则走代理,否则会通过target-action调用同名的OC方法(定义的方法保证同名，参数最多为1个，参数类型可以和前端进行约束)
 */
- (void)addScriptMessageHandler:(id)scriptMessageHandler name:(NSString *)name;
/**
 *  注销 注册过的js回调oc通知方式
 */
- (void)removeScriptMessageHandlerForName:(NSString *)name;

- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id result, NSError *error))completionHandler;

///不建议使用这个办法  因为会在内部等待webView 的执行结果
- (NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)javaScriptString;

/**
 注入脚本,注意避免重复注入(js...)
 
 @param source 注入的内容
 @param injectionTime 注入时间
 @param mainFrameOnly 只作用主框架
 */
- (void)addUserScriptWithSource:(NSString *)source injectionTime:(WKUserScriptInjectionTime)injectionTime forMainFrameOnly:(BOOL)mainFrameOnly;
/**
 移除所有注入的脚本
 */
- (void)removeAllUserScripts;

@end

/**
 Cookie相关
 */
@protocol VDWebViewCookiesProtocol <NSObject>
/**
 不同步NSHTTPCookieStorage存储的cookies 默认同步:NO
 同步NSHTTPCookieStorage中的cookie到WKWebView中，有可能会污染WKWebView中的cookie管理
 */
@property (nonatomic, assign)BOOL httpCookiesDisable;
/**
 设置cookie
 
 @param key 键
 @param value 值
 @param expires 有效时间单位为秒:当值小于等于0时为临时cookie
 @param domain 域名
 */
- (void)setCookieWithKey:(NSString *)key value:(NSString *)value expires:(NSTimeInterval)expires domain:(NSString *)domain;
- (void)setCookies:(NSString *)cookies;
- (NSArray *)getCookies;

@end


/**
 代理方法
 */
@protocol VDWebViewDelegate <NSObject>
@optional
/// 类UIWebView代理方法
- (void)webViewDidStartLoad:(VDWebView *)webView;
- (void)webViewDidFinishLoad:(VDWebView *)webView;
- (void)webView:(VDWebView *)webView didFailLoadWithError:(NSError *)error;
- (BOOL)webView:(VDWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
/**
 JS调原生代理方法(注册了过的方法将全部通过此方法回调)
 
 @param webView VDWebView
 @param message 回调消息
 */
- (void)webView:(VDWebView *)webView didReceiveScriptMessage:(WKScriptMessage *)message;

/**
 JS弹框拦截方法--如果需要自定义弹框建议声明此方法(前提条件：不开启默认系统弹框)
 
 @param webView VDWebView
 @param type 弹框类型
 @param title 标题
 @param content 内容
 @param completionHandler 结果处理必须执行completionHandler(data)
 */
- (void)webView:(VDWebView *)webView showAlertWithType:(VDJSAlertType)type title:(NSString *)title content:(NSString *)content completionHandler:(void (^)(id))completionHandler;
@end
