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
typedef NS_ENUM(NSInteger, VDJSAlertType) {
    VDJSAlertTypeAlert = 0,
    VDJSAlertTypeConfirm,
    VDJSAlertTypePrompt
};
@class VDWebView;
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
 JS弹框拦截方法--如果需要自定义弹框建议声明此方法

 @param webView VDWebView
 @param type 弹框类型
 @param title 标题
 @param content 内容
 @param completionHandler 结果处理必须执行completionHandler(data)
 */
- (void)webView:(VDWebView *)webView showAlertWithType:(VDJSAlertType)type title:(NSString *)title content:(NSString *)content completionHandler:(void (^)(id))completionHandler;
@end
@interface VDWebView : UIView
@property(nonatomic, assign) id<VDWebViewDelegate> delegate;

///内部使用的webView
@property (nonatomic, readonly) WKWebView *realWebView;
@property (nonatomic, readonly) NSURLRequest *originRequest;
///预估网页加载进度
@property (nonatomic, readonly) double estimatedProgress;
// 是否显示进度条 默认不显示
@property (nonatomic, assign) BOOL isShowProgressBar;
///进度条
@property (nonatomic, strong) UIView *progressBar;
/**
 web页面加载完毕后的内容高度(在页面加载完成后获取)
 */
@property (nonatomic, readonly) CGFloat *contentHeight;
/// 是否启用js调用原生弹框 默认为NO 禁止(默认加载弹框在根试图)
@property (nonatomic, assign) BOOL enableAllAlert;
@property (nonatomic, assign) BOOL enableAlert;
@property (nonatomic, assign) BOOL enableConfirm;
@property (nonatomic, assign) BOOL enablePrompt;

///back 层数
- (NSInteger)countOfHistory;
- (void)gobackWithStep:(NSInteger)step;

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

///是否根据视图大小来缩放页面  默认为YES
@property (nonatomic) BOOL scalesPageToFit;

- (id)goBack;
- (id)goForward;
- (id)reload;
- (id)reloadFromOrigin;
- (void)stopLoading;

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

- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id, NSError *))completionHandler;
///不建议使用这个办法  因为会在内部等待webView 的执行结果
- (NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)javaScriptString __deprecated_msg("Method deprecated. Use [evaluateJavaScript:completionHandler:]");

/**
 注入脚本(js...)

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
