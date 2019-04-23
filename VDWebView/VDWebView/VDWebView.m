//
//  VDWebView.m
//  Common
//
//  Created by volientDuan on 2018/12/19.
//  Copyright © 2018 volientDuan. All rights reserved.
//
#import "VDWebView.h"
#import <TargetConditionals.h>
#import <dlfcn.h>
#import "VDWebViewScriptMessageHandler.h"

@interface VDWebView()< WKNavigationDelegate, WKUIDelegate>

@property (nonatomic, assign) CGFloat innerHeight;
@property (nonatomic, assign) CGFloat estimatedProgress;
@property (nonatomic, strong) NSURLRequest *originRequest;
@property (nonatomic, strong) NSURLRequest *currentRequest;

@property (nonatomic, copy) NSString *title;

@property (nonatomic, strong) VDWebViewScriptMessageHandler *innerScriptMessageHandler;
@property (nonatomic, weak) id scriptMessageHandler;

@end


@implementation VDWebView

@synthesize realWebView = _realWebView;
@synthesize scalesPageToFit = _scalesPageToFit;
@synthesize httpCookiesDisable;
@synthesize contentHeight;
@synthesize enableAlert;
@synthesize enablePrompt;
@synthesize enableConfirm;
@synthesize enableAllAlert;
@synthesize isShowProgressBar;
@synthesize progressBar = _progressBar;
@synthesize bridge = _bridge;
//@synthesize jsHandler;

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        
        [self _initMyself];
    }
    return self;
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
}


- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        
        [self _initMyself];
    }
    return self;
    
}

- (void)_initMyself {
    
    [self initWKWebView];
    [self.realWebView setFrame:self.bounds];
    [self.realWebView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    [self addSubview:self.realWebView];
}
- (void)initWKWebView {
    
    WKWebViewConfiguration* configuration = [[ WKWebViewConfiguration alloc] init];
    configuration.preferences = [NSClassFromString(@"WKPreferences") new];
    configuration.userContentController = [WKUserContentController new];
    
    WKWebView* webView = [[WKWebView alloc] initWithFrame:self.bounds configuration:configuration];
    webView.UIDelegate = self;
    webView.navigationDelegate = self;
    
    webView.backgroundColor = [UIColor clearColor];
    webView.opaque = NO;
    
    [webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    [webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
    _realWebView = webView;
    
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if([keyPath isEqualToString:@"estimatedProgress"]) {
        
        self.estimatedProgress = [change[NSKeyValueChangeNewKey] floatValue];
        // 判断是否显示进度条
        if (self.isShowProgressBar) {
            
            self.progressBar.frame = CGRectMake(0, 0, self.bounds.size.width*self.estimatedProgress, self.progressBar.bounds.size.height);
            if (self.estimatedProgress == 1) {
                
                self.progressBar.hidden = YES;
            } else {
                
                self.progressBar.hidden = NO;
            }
        }
    }
    if ([keyPath isEqualToString:@"title"]) {
        
        self.title = change[NSKeyValueChangeNewKey];
    }
}

#pragma mark - 加载进度条
- (UIView *)progressBar {
    if (!_progressBar) {
        _progressBar = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 0, 2)];
        _progressBar.backgroundColor = UIColor.greenColor;
        [self addSubview:_progressBar];
    }
    return _progressBar;
}

#pragma mark- WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    BOOL resultBOOL = [self callback_webViewShouldStartLoadWithRequest:navigationAction.request navigationType:navigationAction.navigationType];
    if (resultBOOL) {
        
        self.currentRequest = navigationAction.request;
        if (navigationAction.targetFrame == nil) {
            
            [webView loadRequest:navigationAction.request];
        }
        decisionHandler(WKNavigationActionPolicyAllow);
    } else {
        
        decisionHandler(WKNavigationActionPolicyCancel);
    }
}
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    
    if (!self.httpCookiesDisable) {
        // 同步NSHTTPCookieStorage中的cookie到WKWebView中，有可能会污染WKWebView中的cookie管理
        // WKWebView有自己的cookie管理
        NSArray *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage].cookies;
        for (NSHTTPCookie *cookie in cookies) {
            if ([navigationResponse.response.URL.host containsString:cookie.domain]) {
                [self setCookieWithKey:cookie.name value:cookie.value expires:[cookie.expiresDate timeIntervalSinceNow] domain:cookie.domain];
            }
        }
    }
    decisionHandler(WKNavigationResponsePolicyAllow);
}
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    
    [self callback_webViewDidStartLoad];
}
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [webView evaluateJavaScript:@"document.body.offsetHeight" completionHandler:^(id data, NSError *error) {
        self.innerHeight = [data floatValue];
        if ([self.delegate respondsToSelector:@selector(webView:innerHeight:)]) {
            [self.delegate webView:self innerHeight:self.innerHeight];
        }
    }];
    [self callback_webViewDidFinishLoad];
}
- (void)webView:(WKWebView *) webView didFailProvisionalNavigation: (WKNavigation *) navigation withError: (NSError *) error {
    
    [self callback_webViewDidFailLoadWithError:error];
}
- (void)webView: (WKWebView *)webView didFailNavigation:(WKNavigation *) navigation withError: (NSError *) error {
    
    [self callback_webViewDidFailLoadWithError:error];
}

#pragma mark- WKUIDelegate
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    
    if (self.enableAlert||self.enableAllAlert) {
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:message message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
            completionHandler();
        }]];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
    } else {
        
        if ([self.delegate respondsToSelector:@selector(webView:showAlertWithType:title:content:completionHandler:)]) {
            
            [self.delegate webView:self showAlertWithType:VDJSAlertTypeAlert title:message content:nil completionHandler:^(id data) {
                completionHandler();
            }];
        }
    }
}
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler {
    
    if (self.enableConfirm||self.enableAllAlert) {
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:([UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            completionHandler(NO);
        }])];
        [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            completionHandler(YES);
        }])];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
    } else {
        
        if ([self.delegate respondsToSelector:@selector(webView:showAlertWithType:title:content:completionHandler:)]) {
            
            [self.delegate webView:self showAlertWithType:VDJSAlertTypeConfirm title:@"提示" content:message completionHandler:^(id data) {
                completionHandler([data boolValue]);
            }];
        }
    }
    
}
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler {
    
    if (self.enablePrompt||self.enableAllAlert) {
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:prompt message:@"" preferredStyle:UIAlertControllerStyleAlert];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.text = defaultText;
        }];
        [alertController addAction:([UIAlertAction actionWithTitle:@"完成" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            completionHandler(alertController.textFields[0].text?:@"");
        }])];
        
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
    } else {
        
        if ([self.delegate respondsToSelector:@selector(webView:showAlertWithType:title:content:completionHandler:)]) {
            
            [self.delegate webView:self showAlertWithType:VDJSAlertTypePrompt title:prompt content:defaultText completionHandler:^(id data) {
                
                completionHandler(data == nil ? @"":[data stringValue]);
            }];
        }
    }
}
#pragma mark- CALLBACK WebView Delegate

- (void)callback_webViewDidFinishLoad {
    
    if([self.delegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        
        [self.delegate webViewDidFinishLoad:self];
    }
}
- (void)callback_webViewDidStartLoad {
    
    if([self.delegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        
        [self.delegate webViewDidStartLoad:self];
    }
}
- (void)callback_webViewDidFailLoadWithError:(NSError *)error {
    
    if ([self.delegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        
        [self.delegate webView:self didFailLoadWithError:error];
    }
}
-(BOOL)callback_webViewShouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(NSInteger)navigationType {
    
    BOOL resultBOOL = YES;
    if ([self.delegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
        
        if (navigationType == -1) {
            
            navigationType = UIWebViewNavigationTypeOther;
        }
        resultBOOL = [self.delegate webView:self shouldStartLoadWithRequest:request navigationType:navigationType];
    }
    return resultBOOL;
}

#pragma mark - VDWebViewScriptProtocol
- (VDWebViewScriptMessageHandler *)innerScriptMessageHandler {
    
    if (!_innerScriptMessageHandler) {
        _innerScriptMessageHandler = [[VDWebViewScriptMessageHandler alloc]initWithTarget:self selector:@selector(didReceiveScriptMessage:)];
    }
    return _innerScriptMessageHandler;
}

/**
 *  添加js回调oc通知方式，适用于 iOS8 之后
 */
- (void)addScriptMessageHandler:(id)scriptMessageHandler name:(NSString *)name {
    
    // 先只允许添加一个hander对象
    self.scriptMessageHandler = scriptMessageHandler;
    __block BOOL isHaved = NO;
    [self.innerScriptMessageHandler.scriptMessageNames enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([obj isEqualToString:name]) {
            isHaved = YES;
        }
    }];
    if (!isHaved) {
        
        [self.innerScriptMessageHandler.scriptMessageNames addObject:name];
        [self.realWebView.configuration.userContentController addScriptMessageHandler:self.innerScriptMessageHandler name:name];
    }
}

/**
 *  注销 注册过的js回调oc通知方式，适用于 iOS8 之后
 */
- (void)removeScriptMessageHandlerForName:(NSString *)name {
    
    [_realWebView.configuration.userContentController removeScriptMessageHandlerForName:name];
}

/**
 *  注销 注册过的js回调oc通知方式，适用于 iOS8 之后
 */
- (void)removeScriptMessageHandler {
    if (!_innerScriptMessageHandler) {
        return;
    }
    for (NSString *name in self.innerScriptMessageHandler.scriptMessageNames) {
        
        [self removeScriptMessageHandlerForName:name];
    }
}
- (void)didReceiveScriptMessage:(WKScriptMessage *)message {
    
    if ((![self.delegate isKindOfClass:[VDWebViewJSBridge class]] && [self.delegate respondsToSelector:@selector(webView:didReceiveScriptMessage:)]) || ([self.delegate isKindOfClass:[VDWebViewJSBridge class]] && ((VDWebViewJSBridge *)self.delegate).didReceiveScriptMessage)) {
        
        [self.delegate webView:self didReceiveScriptMessage:message];
    }else {
        
        SEL sel = NSSelectorFromString(message.name);
        NSMethodSignature *sign = [self.scriptMessageHandler methodSignatureForSelector:sel];
        BOOL isHavedParam = NO;
        if (!sign) {
            isHavedParam = YES;
            sel = NSSelectorFromString([NSString stringWithFormat:@"%@:",message.name]);
            sign = [self.scriptMessageHandler methodSignatureForSelector:sel];
        }
        if (sign) {
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sign];
            [invocation setTarget:self.scriptMessageHandler];
            [invocation setSelector:sel];
            if (isHavedParam) {
                id param = message.body;
                [invocation setArgument:&(param) atIndex:2];
            }
            [invocation invoke];
        }else {
            NSLog(@"未定义方法: %@或%@:\nwaring:最多支持一个参数的自定义方法",message.name,message.name
                  );
        }
    }
}

- (void)addUserScriptWithSource:(NSString *)source injectionTime:(WKUserScriptInjectionTime)injectionTime forMainFrameOnly:(BOOL)mainFrameOnly {
    
    WKUserScript *script = [[WKUserScript alloc]initWithSource:source injectionTime:injectionTime forMainFrameOnly:mainFrameOnly];
    [self.realWebView.configuration.userContentController addUserScript:script];
}

- (void)removeAllUserScripts {
    
    [self.realWebView.configuration.userContentController removeAllUserScripts];
}

#pragma mark- 基础方法
- (UIScrollView *)scrollView {
    
    return [(id)self.realWebView scrollView];
}

- (id)loadRequest:(NSURLRequest *)request {
    
    self.originRequest = request;
    self.currentRequest = request;
    return [(WKWebView*)self.realWebView loadRequest:request];
}
- (id)loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL {
    
    return [(WKWebView*)self.realWebView loadHTMLString:string baseURL:baseURL];
}
- (NSURLRequest *)currentRequest {
    
    return _currentRequest;
}
- (NSURL *)URL {
    
    return [(WKWebView*)self.realWebView URL];
}
- (BOOL)isLoading {
    
    return [self.realWebView isLoading];
}
- (BOOL)canGoBack {
    
    return [self.realWebView canGoBack];
}
- (BOOL)canGoForward {
    
    return [self.realWebView canGoForward];
}
- (id)goBack {
    
    return [(WKWebView*)self.realWebView goBack];
}
- (id)goForward {
    
    return [(WKWebView*)self.realWebView goForward];
}
- (id)reload {
    
    return [(WKWebView*)self.realWebView reload];
}
- (id)reloadFromOrigin {
    
    return [(WKWebView*)self.realWebView reloadFromOrigin];
}
- (void)stopLoading {
    
    [self.realWebView stopLoading];
}

- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id, NSError *))completionHandler {
    
    return [(WKWebView*)self.realWebView evaluateJavaScript:javaScriptString completionHandler:completionHandler];
}

- (NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)javaScriptString {
    
    __block NSString* result = nil;
    __block BOOL isExecuted = NO;
    [(WKWebView*)self.realWebView evaluateJavaScript:javaScriptString completionHandler:^(id obj, NSError *error) {
        
        result = obj;
        isExecuted = YES;
    }];
    
    while (isExecuted == NO) {
        
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    return result;
}

- (void)setScalesPageToFit:(BOOL)scalesPageToFit {
    
    if (_scalesPageToFit == scalesPageToFit) {
        
        return;
    }
    WKWebView* webView = _realWebView;
    
    NSString *jScript = @"var meta = document.createElement('meta'); \
    meta.name = 'viewport'; \
    meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'; \
    var head = document.getElementsByTagName('head')[0];\
    head.appendChild(meta);";
    
    if (scalesPageToFit) {
        
        WKUserScript *wkUScript = [[NSClassFromString(@"WKUserScript") alloc] initWithSource:jScript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:NO];
        [webView.configuration.userContentController addUserScript:wkUScript];
    } else {
        
        NSMutableArray* array = [NSMutableArray arrayWithArray:webView.configuration.userContentController.userScripts];
        for (WKUserScript *wkUScript in array) {
            
            if ([wkUScript.source isEqual:jScript]) {
                
                [array removeObject:wkUScript];
                break;
            }
        }
        for (WKUserScript *wkUScript in array) {
            
            [webView.configuration.userContentController addUserScript:wkUScript];
        }
    }
    
    _scalesPageToFit = scalesPageToFit;
}
- (BOOL)scalesPageToFit {
    
    return _scalesPageToFit;
}

- (NSInteger)countOfHistory {
    
    WKWebView* webView = self.realWebView;
    return webView.backForwardList.backList.count;
}
- (void)gobackWithStep:(NSInteger)step {
    if (self.canGoBack == NO) {
        return;
    }
    if (step > 0) {
        NSInteger historyCount = self.countOfHistory;
        if (step >= historyCount) {
            step = historyCount - 1;
        }
        WKWebView* webView = self.realWebView;
        WKBackForwardListItem* backItem = webView.backForwardList.backList[step];
        [webView goToBackForwardListItem:backItem];
    } else {
        [self goBack];
    }
}

- (VDWebViewJSBridge *)bridgeInitialized {
    
    _bridge = [[VDWebViewJSBridge alloc]initWithWebView:self delegate:self.delegate];
    return _bridge;
}

- (void)setDelegate:(id<VDWebViewDelegate>)delegate {
    
    if (_bridge) {
        _bridge.delegate = delegate;
    } else {
        _delegate = delegate;
    }
}

- (CGFloat)contentHeight {
    return self.innerHeight;
}


#pragma mark-  如果没有找到方法 去realWebView 中调用
- (BOOL)respondsToSelector:(SEL)aSelector {
    
    BOOL hasResponds = [super respondsToSelector:aSelector];
    if (hasResponds == NO) {
        
        hasResponds = [self.delegate respondsToSelector:aSelector];
    }
    
    if (hasResponds == NO) {
        
        hasResponds = [self.realWebView respondsToSelector:aSelector];
    }
    return hasResponds;
}

- (NSMethodSignature*)methodSignatureForSelector:(SEL)selector {
    
    NSMethodSignature* methodSign = [super methodSignatureForSelector:selector];
    if (methodSign == nil) {
        if ([self.realWebView respondsToSelector:selector]) {
            
            methodSign = [self.realWebView methodSignatureForSelector:selector];
        } else {
            
            methodSign = [(id)self.delegate methodSignatureForSelector:selector];
        }
    }
    return methodSign;
}

- (void)forwardInvocation:(NSInvocation*)invocation {
    
    if ([self.realWebView respondsToSelector:invocation.selector]) {
        
        [invocation invokeWithTarget:self.realWebView];
    } else {
        
        [invocation invokeWithTarget:self.delegate];
    }
}


#pragma mark - VDWebViewCookiesProtocol

- (void)setCookieWithKey:(NSString *)key value:(NSString *)value expires:(NSTimeInterval)expires domain:(NSString *)domain {
    // 其实就是通过注入设置cookie的js代码并在load前执行(iOS11以上也可通过WKHTTPCookieStore进行cookie的设置)
    NSString *jsSource = [NSString stringWithFormat:@"document.cookie = \"%@=%@",key,value];
    if (expires > 0) {
        jsSource = [NSString stringWithFormat:@"%@;expires=%lf",jsSource,expires*1000];
    }
    if (domain) {
        jsSource = [NSString stringWithFormat:@"%@;domain=%@",jsSource,domain];
    }
    jsSource = [NSString stringWithFormat:@"%@;domain=%@\"",jsSource,domain];
    [self addUserScriptWithSource:jsSource injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    
}

- (NSArray *)getCookies {
    __block NSArray *cookieArr;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_11_0
    if (@available(iOS 11.0, *)) {
        __block BOOL isExecuted = NO;
        [self.realWebView.configuration.websiteDataStore.httpCookieStore getAllCookies:^(NSArray<NSHTTPCookie *> * cookies) {
            cookieArr = cookies;
            isExecuted = YES;
        }];
        while (isExecuted == NO) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
    }
#else
    
#endif
    return cookieArr;
}

- (void)setCookies:(NSString *)cookies {
    NSString *str = [cookies stringByReplacingOccurrencesOfString:@" " withString:@""];
    str = [str stringByReplacingOccurrencesOfString:@"Domain=" withString:@"domain="];
    str = [str stringByReplacingOccurrencesOfString:@"Max-Age=" withString:@"expires="];
    str = [str stringByReplacingOccurrencesOfString:@"Path=" withString:@"path="];
    NSArray *array = [str componentsSeparatedByString:@";"];
    if (array.count > 0) {
        NSString *key,*value,*domain,*expires,*path;
        for (NSString *itemStr in array) {
            NSArray *items = [itemStr componentsSeparatedByString:@"="];
            if (items.count == 2) {
                if ([items[0] isEqualToString:@"domain"]) {
                    domain = items[1];
                }else if ([items[0] isEqualToString:@"expires"]) {
                    expires = items[1];
                }else if ([items[0] isEqualToString:@"path"]) {
                    path = items[1];
                }else {
                    if (key) {
                        [self setCookieWithKey:key value:value expires:-1 domain:domain];
                    }
                    key = items[0];
                    value = items[1];
                    domain = nil;
                }
            }
        }
        if (key) {
            [self setCookieWithKey:key value:value expires:-1 domain:domain];
        }
    }
}

#pragma mark- 清理
-(void)dealloc {
    WKWebView* webView = _realWebView;
    webView.UIDelegate = nil;
    webView.navigationDelegate = nil;
    
    [webView removeObserver:self forKeyPath:@"estimatedProgress"];
    [webView removeObserver:self forKeyPath:@"title"];
    
    // 如果添加JS调用OC的监听 dealloc 一定要移除所有 否则handler将无法释放
    [self removeScriptMessageHandler];
    [self removeAllUserScripts];
    [_realWebView scrollView].delegate = nil;
    [_realWebView stopLoading];
    [_realWebView removeFromSuperview];
    _realWebView = nil;
    
    
}

@end
