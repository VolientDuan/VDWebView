[VDWebView的源码和使用示例](https://github.com/VolientDuan/VDWebView)

> VDWebView是目前最新、最全和最方便的WebView，可通过pod更新迭代；设计方案为Protocol和Target-Action；有任何问题欢迎指出。

## VDWebView的优势
* 以最少的成本替代旧项目中的UIWebView
    * 熟悉的代理方法
    * 常用的基本方法和属性
    * 使用起来更加的熟悉只需把`UIWebView`名更换为`VDWebView`
* 更加方便和安全的JS与OC方法相互调用(后面我会具体说明解决方案)
    * 支持以target-action的方式替代delegate(两者任意选择)
    * 不会出现类似于使用WKWebView注册OC方法忘记注销导致循环引用无法释放的问题
* 提供加载进度条的使用、预估进度值的读取等
* cookie的操作
* iOS和Android通用的JS与OC交互方法(通过请求拦截实现)
## CocoaPods
```
pod 'VDWebView', '~> 1.1.0'
```

## 基本描述
* 为什么用的是`WKWebView`
* 提供熟悉和更加便捷的属性和方法(结合了`UIWebView`和`WKWebView`)
* JS调用OC方法的绑定
* JS的调用和注入

## 为什么使用WKWebView
* `WKWebView`是iOS8后推出的WebKit框架中的控件，由于iOS12后已经弃用`UIWebView`了而且现在的大多数项目只适配到iOS8
* 加载速度优于`UIWebView`且解决了加载网页时的内存泄露问题
* 在和JS交互方面提供了桥梁`WKUserContentController`
* 没好处这东西出来干嘛，所以综上用起来吧

## 提供了哪些更加熟悉和更加便捷的属性和方法
#### VDWebViewDelegate
* 类`UIWebView`代理方法，处理对象(`WKNavigationDelegate`)

```
/// 类UIWebView代理方法
- (void)webViewDidStartLoad:(VDWebView *)webView;
- (void)webViewDidFinishLoad:(VDWebView *)webView;
- (void)webView:(VDWebView *)webView didFailLoadWithError:(NSError *)error;
- (BOOL)webView:(VDWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
```
* 对`WKUIDelegate`和`WKScriptMessageHandler`代理的合并

```
/**
 JS调原生代理方法(注册了过的方法将全部通过此方法回调)
 */
- (void)webView:(VDWebView *)webView didReceiveScriptMessage:(WKScriptMessage *)message;

/**
 JS弹框拦截方法--如果需要自定义弹框建议声明此方法
 */
- (void)webView:(VDWebView *)webView showAlertWithType:(VDJSAlertType)type title:(NSString *)title content:(NSString *)content completionHandler:(void (^)(id))completionHandler;
```

#### 新增了哪些属性和方法

```
///预估网页加载进度
@property (nonatomic, readonly) CGFloat estimatedProgress;
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

```

## JS调用OC方法的绑定

在使用`WKWebView`时我们需要调用`WKWebView`内`configuration`中的`userContentController`所属类`WKUserContentController`提供的实例方法进行注册，具体方法如下:
 
 ```
- (void)addScriptMessageHandler:(id <WKScriptMessageHandler>)scriptMessageHandler name:(NSString *)name;
 ```
对应的注销方法为:

```
- (void)removeScriptMessageHandlerForName:(NSString *)name;
```

#### 已知的循环引用问题

在使用`addScriptMessageHandler:name:`方法注册时传入的这个handler被循环引用，如果不调用对应的注销方法就会导致handler这个对象无法被释放，如果你这个handler传入是webView所在的控制器，那么你就要在销毁这个控制器前注销掉你注册的方法.

tip： 如何知道控制器有没有被释放，重写dealloc()，没走此方法说明未被释放

#### VDWebView是如何解决循环引用问题

简要分析可分为下面三步

* 使用`VDScripMessageHandler`作为注册的handler
    * 继承协议`WKScriptMessageHandler`
    * 提供target-action回调方式
* 保存注册记录
* 在`VDWebView`的`dealloc()`方法中获取注册记录并注销

这些做的好处在于你在使用VDWebView时无需自己去一个个手动注销了(如果你注册的方法多的话那就是噩梦了)

#### VDWebView是如何进行方法的注册和回调的

* 方法的注册

```
- (void)addScriptMessageHandler:(id)scriptMessageHandler name:(NSString *)name;
```

* JS调用说明

```
// 没效果可使用try-catch
window.webkit.messageHandlers.#OC方法名#.postMessage(#参数#)

```

回调方式分两种：delegate和target-action; 两种方式只能存一，优先delegate

* delegate方式，只需在控制器中声明`VDWebViewDelegate`中的方法

```
- (void)webView:(VDWebView *)webView didReceiveScriptMessage:(WKScriptMessage *)message;
```
* target-action方式
    * 不能声明上述的代理方法
    * 在控制器(方法注册传入的scriptMessageHandler)中声明同名的OC方法

#### 为什么要增加target-action的方式
> target-action：目标－动作模式,拜C语言所赐,更是灵活很多,编译期没有任何检查,都是运行时的绑定

* 在`VDWebView`中就是通过`NSSelectorFromString()`动态加载方法，再通过`NSMethodSignature`和`NSInvocation`进行方法的签名和调用
* 这样就可以充分的体现JS调用对应的OC方法和一对一更加清晰和方便处理

## JS的调用和注入

可通过两种方式进行JS方法的调用，推荐第一种

* WKWebView的同名方法

```
- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id, NSError *))completionHandler;

```
* UIWebView的同名方法（不建议使用这个办法，因为会在内部等待执行结果）

```
- (NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)javaScriptString;
```

脚本的注入和移除

```
/**
 注入脚本(js...)
 */
- (void)addUserScriptWithSource:(NSString *)source injectionTime:(WKUserScriptInjectionTime)injectionTime forMainFrameOnly:(BOOL)mainFrameOnly;

/**
 移除所有注入的脚本
 */
- (void)removeAllUserScripts;
```
## cookie的处理(待优化)

#### 提供cookie的共享
由于WKWebView的cookie是和NSHTTPCookieStorage不共享，这就造成使用WKWebView打开的web页面无法获取到通过原生请求登录的cookie，当然其它解决方案有很多种，比如
* 通过调用URL的拼接把登录信息传递过去
* 通过js方法传值

但是用了VDWebView就不需要考虑cookie的问题了，因为它已经默认把cookie带过去了，当然你也可以手动去关闭

通过协议`VDWebViewCookiesProtocol`提供相关API和属性
```
/**
 不同步NSHTTPCookieStorage存储的cookies 默认同步:NO
 同步NSHTTPCookieStorage中的cookie到WKWebView中，有可能会污染WKWebView中的cookie管理
 */
@property (nonatomic, assign)BOOL httpCookiesDisable;
/**
 设置cookie
 */
- (void)setCookieWithKey:(NSString *)key value:(NSString *)value expires:(NSTimeInterval)expires domain:(NSString *)domain;
- (void)setCookies:(NSString *)cookies;
- (NSArray *)getCookies;
```


## 后续版本思考和设计中
* ~~cookie的处理~~
* ~~拦截webView内部请求通过自定义URL的方式进行JS交互~~
* APP和web资源共享问题：比如图片

