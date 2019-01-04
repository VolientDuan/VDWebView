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
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.view addSubview:self.webView];
    self.webView.isShowProgressBar = YES;
    self.webView.enableAllAlert = YES;
//    NSString *path = [[NSBundle mainBundle]pathForResource:@"wkweb.html" ofType:nil];
//    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
//    [self.webView setCookieWithKey:@"SID" value:@"I9whREm1dLj5IuiifvDCYVZyLz5tIuJQ5b0w" expires:-1 domain:@".ele.me"];
//    [self.webView setCookieWithKey:@"USERID" value:@"2267603162" expires:-1 domain:@".ele.me"];
//    [self.webView setCookieWithKey:@"UTUSER" value:@"2267603162" expires:-1 domain:@".ele.me"];
//    [self.webView setCookieWithKey:@"_utrace" value:@"6a187ba6de496b9bc97364abe33401fc_2019-01-03" expires:-1 domain:@".ele.me"];
//    [self.webView setCookieWithKey:@"cna" value:@"QfFKFDDq/F4CAXAQR/C/ZAtr" expires:-1 domain:@".ele.me"];
//    [self.webView setCookieWithKey:@"eleme__ele_me" value:@"3A53697b357cd18a741c9716da6fa22fbf0bcc4055" expires:-1 domain:@".ele.me"];
//    [self.webView setCookieWithKey:@"isg" value:@"BLCw6FwomJ7KKUSfZO2mi01RgXiu6YSKASLeT6oBc4veZVMPVggk08MUuWsFdUwb" expires:-1 domain:@".ele.me"];
//    [self.webView setCookieWithKey:@"l" value:@"aBtZCNlGyuzT4qsB2MaiBlD4gOqxT05PAPYT1Mayri7404ZmVU4dxjno-VwW7_qC5zTy_K-5F" expires:-1 domain:@".ele.me"];
//    [self.webView setCookieWithKey:@"track_id" value:@"1546497114%7C6cb6deaa18f2a63f0cad110f74fe03f9500c179f6eb1c7fed8%7C1a494cadafcfd6013abd76c77cbe9c3d" expires:-1 domain:@".ele.me"];
//    [self.webView setCookieWithKey:@"ubt_ssid" value:@"8n1djzs0msdy0bduqfb9e0t01y4hx3kw_2019-01-03" expires:-1 domain:@".ele.me"];
    [self.webView setCookies:@"id=16272;track_id=1546500647|666cc9a02e0624e67f2e1735faa206b7b22579db6ae770da24|2ff88c34f15aa096bf13ec6fa6d52a77; Path=/; Domain=ele.me; Max-Age=311040000;USERID=2267603162; Domain=.ele.me; Max-Age=31536000; Path=/; HttpOnly;UTUSER=2267603162; Domain=.ele.me; Max-Age=31536000; Path=/;SID=I9whREm1dLj5IuiifvDCYVZyLz5tIuJQ5b0w; Domain=.ele.me; Max-Age=31536000; Path=/; HttpOnly"];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://h5.ele.me/"]]];
//    [self addJSHandle];
}

#pragma mark - delegate

- (void)webViewDidStartLoad:(VDWebView *)webView {
    
}

- (void)webViewDidFinishLoad:(VDWebView *)webView {
    
}

- (BOOL)webView:(VDWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSLog(@"should start loading:%@",request.URL.absoluteString);
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
