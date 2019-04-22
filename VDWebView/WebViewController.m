//
//  WebViewController.m
//  Common
//
//  Created by volientDuan on 2018/12/19.
//  Copyright © 2018 volientDuan. All rights reserved.
//

#import "WebViewController.h"
#import "VDWebView.h"
@interface WebViewController ()<VDWebViewDelegate>
@property (nonatomic, strong)VDWebView *webView;

@end

@implementation WebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    self.title = @"加载本地html调试";
    
    [self.view addSubview:self.webView];
    self.webView.isShowProgressBar = YES;
    self.webView.enableAllAlert = YES;
    [self.webView bridgeInitialized];
    
    NSString *path = [[NSBundle mainBundle]pathForResource:@"wkweb.html" ofType:nil];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
//    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://localhost:8080"]]];
    [self addJSHandle];
    
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}

#pragma mark - delegate

- (void)webViewDidStartLoad:(VDWebView *)webView {
    
}

- (void)webViewDidFinishLoad:(VDWebView *)webView {
    NSLog(@"%f",webView.contentHeight);
}

- (BOOL)webView:(VDWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSLog(@"\nshould start loading:%@",request.URL.absoluteString);
    return YES;
}

#pragma mark - 注册方法
- (void)addJSHandle {
    [self.webView addScriptMessageHandler:self name:@"popView"];
    [self.webView addScriptMessageHandler:self name:@"reloadView"];
    [self.webView addScriptMessageHandler:self name:@"changeTitle"];
    [self.webView addScriptMessageHandler:self name:@"sendMessage"];
    [self.webView addScriptMessageHandler:self name:@"injectJS"];
}

#pragma mark - js->oc的一些方法
- (void)popView:(NSDictionary *)info {
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)reloadView {
    [self.webView reload];
}
- (void)changeTitle:(NSString *)title {
    self.title = title;
}
- (void)sendMessage:(NSString *)msg {
    NSLog(@"%@",msg);
}
- (void)injectJS {
    // 注入
    [self.webView addUserScriptWithSource:@"alert(\"简单的注入个Alert\")" injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    // reload生效
    [self.webView reload];
}

#pragma mark - jsBridge

- (void)jsBridgeTest:(NSDictionary *)params {
    
    NSLog(@"\njsBridge:%@",params);
}

- (void)testJSBridgeToJS:(NSDictionary *)params {
    [self.webView.bridge executeJsMethod:params[@"method"] params:@[@"1",@"2",@"3"] completionHandler:^(id result, NSError *error) {
        NSLog(@"\njs方法执行h结果回调：%@\n错误信息:%@",result,error);
    }];
}

#pragma mark - property
- (VDWebView *)webView {
    if (!_webView) {
        _webView = [[VDWebView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-88)];
        _webView.delegate = self;
    }
    return _webView;
}

- (void)dealloc {
    NSLog(@"释放webViewController");
}

@end
