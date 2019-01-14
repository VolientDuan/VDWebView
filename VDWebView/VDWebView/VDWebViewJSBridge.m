//
//  VDWebViewJSBridge.m
//  VDWebView
//
//  Created by volientDuan on 2019/1/11.
//  Copyright © 2019 volientDuan. All rights reserved.
//

#import "VDWebViewJSBridge.h"
#import <TargetConditionals.h>
#import <dlfcn.h>

#define VDWebViewJSBridgeScheme @"vdjsbridge"

@interface VDURLParse : NSObject
@property (nonatomic, strong)NSString *method;
@property (nonatomic, strong)id params;
- (instancetype)initWithUrl:(NSURL *)url;

@end
@implementation VDURLParse
- (instancetype)initWithUrl:(NSURL *)url {
    
    self = [super init];
    if (self) {
        [self parseUrl:url];
    }
    return self;
}

- (void)parseUrl:(NSURL *)url {
    self.method = url.host;
    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithString:url.absoluteString];
    //回调遍历所有参数，添加入字典
    __block id value = nil;
    [urlComponents.queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.name isEqualToString:@"params"]) {
            value = obj.value;
            *stop = YES;
        }
    }];
    if (value) {
        // base64解码
        NSData *data = [[NSData alloc]initWithBase64EncodedString:value options:NSDataBase64DecodingIgnoreUnknownCharacters];
        NSString *string = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        self.params = [self paramsWithJsonString:string];
    }
}

- (id)paramsWithJsonString:(NSString *)jsonString {
    
    if (jsonString == nil) {
        return nil;
    }
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    id obj = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers                                           error:&err];
    
    if (err) {
        
        return jsonString;
    }
    return obj;
}

@end

@interface VDWebViewJSBridge()<VDWebViewDelegate>
@property (nonatomic, strong)NSMutableArray *methods;

@end
@implementation VDWebViewJSBridge
- (NSString *)scheme {
    
    if (!_scheme) {
        _scheme = VDWebViewJSBridgeScheme;
    }
    return _scheme;
}

- (NSMutableArray *)methods {
    
    if (!_methods) {
        _methods = [NSMutableArray array];
    }
    return _methods;
}
- (instancetype)initWithWebView:(VDWebView *)webView delegate:(id<VDWebViewDelegate>)delegate {
    
    self = [super init];
    if (self) {
        self.webView = webView;
        self.delegate = delegate;
        self.webView.delegate = nil;
        self.webView.delegate = self;
    }
    return self;
}

- (void)executeJsMethod:(NSString *)method params:(NSArray<NSString *> *)params completionHandler:(void (^)(id, NSError *))completionHandler{
    NSMutableString *js = [[NSMutableString alloc]initWithString:method];
    NSInteger idx = 0;
    for (NSString *p in params) {
        if (idx == 0) {
            
            [js appendString:@"("];
        } else {
            
            [js appendString:@", "];
        }
        [js appendString:@"\""];
        [js appendString:p];
        [js appendString:@"\""];
        idx ++;
    }
    [js appendString:@")"];
    [self.webView evaluateJavaScript:js completionHandler:completionHandler];
}

- (void)bindMethod:(NSString *)method {
    
    [self.methods addObject:method];
    
}

- (void)removeMethod:(NSString *)method {
    [self.methods enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isEqualToString:method]) {
            [self.methods removeObjectAtIndex:idx];
            *stop = YES;
        }
    }];
}

- (void)removeAllMethod {
    [self.methods removeAllObjects];
}

- (void)executeMethodWithUrl:(NSURL *)url {
    if (self.methods.count) {
        __block BOOL isHaved = NO;
        [self.methods enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isEqualToString:url.host]) {
                isHaved = YES;
                *stop = YES;
            }
        }];
        if (isHaved == NO) {
            return;
        }
    }
    VDURLParse *parse = [[VDURLParse alloc]initWithUrl:url];
    // 调用OC方法
    SEL sel = NSSelectorFromString(parse.method);
    NSMethodSignature *sign = [(id)self.delegate methodSignatureForSelector:sel];
    BOOL isHavedParam = NO;
    if (!sign) {
        isHavedParam = YES;
        sel = NSSelectorFromString([NSString stringWithFormat:@"%@:",parse.method]);
        sign = [(id)self.delegate methodSignatureForSelector:sel];
    }
    if (sign) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sign];
        [invocation setTarget:self.delegate];
        [invocation setSelector:sel];
        if (isHavedParam) {
            id param = parse.params;
            [invocation setArgument:&(param) atIndex:2];
        }
        [invocation invoke];
    }else {
        NSLog(@"未定义方法: %@或%@:\nwaring:最多支持一个参数的自定义方法",parse.method,parse.method);
    }
}

#pragma mark - VDWebViewDelegate

- (void)webViewDidStartLoad:(VDWebView *)webView {
    
    if ([self.delegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [self.delegate webViewDidStartLoad:webView];
    }
}

- (void)webViewDidFinishLoad:(VDWebView *)webView {
    
    if ([self.delegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [self.delegate webViewDidFinishLoad:webView];
    }
}

- (void)webView:(VDWebView *)webView didFailLoadWithError:(NSError *)error {
    
    if ([self.delegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [self.delegate webView:webView didFailLoadWithError:error];
    }
}
- (BOOL)webView:(VDWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    if ([request.URL.scheme isEqualToString:self.scheme]) {
        [self executeMethodWithUrl:request.URL];
        return NO;
    } else {
        if ([self.delegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
            return [self.delegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
        }
    }
    return YES;
}

- (void)webView:(VDWebView *)webView didReceiveScriptMessage:(WKScriptMessage *)message {
    
    if ([self.delegate respondsToSelector:@selector(webView:didReceiveScriptMessage:)]) {
        [self.delegate webView:webView didReceiveScriptMessage:message];
    }
}

- (void)webView:(VDWebView *)webView showAlertWithType:(VDJSAlertType)type title:(NSString *)title content:(NSString *)content completionHandler:(void (^)(id))completionHandler {
    
    if ([self.delegate respondsToSelector:@selector(webView:showAlertWithType:title:content:completionHandler:)]) {
        [self.delegate webView:webView showAlertWithType:type title:title content:content completionHandler:completionHandler];
    }
}

@end
