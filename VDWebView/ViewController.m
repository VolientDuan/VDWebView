//
//  ViewController.m
//  VDWebView
//
//  Created by volientDuan on 2018/12/21.
//  Copyright © 2018 volientDuan. All rights reserved.
//

#import "ViewController.h"
#import "WebViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width/2-100, 100, 200, 50)];
    [btn setTitle:@"调试VDWebView" forState:UIControlStateNormal];
    [btn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:20];
    btn.backgroundColor = UIColor.blackColor;
    [self.view addSubview:btn];
    [btn addTarget:self action:@selector(btnClick) forControlEvents:UIControlEventTouchUpInside];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)btnClick {
    [self.navigationController pushViewController:[WebViewController new] animated:YES];
}

@end
