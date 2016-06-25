//
//  TMMWebVC.m
//  TianMM
//
//  Created by cocoa on 15/9/4.
//  Copyright (c) 2015年 cocoa. All rights reserved.
//

#import "TMMWebVC.h"
#import "TMMQRCodeVc.h"

#define MIN_OS_VERSION  100

@interface TMMWebVC ()< UIWebViewDelegate>

@property (assign,nonatomic) UIWebView *webView;
@property (assign,nonatomic) WebViewJavascriptBridge* bridge;

@end

@implementation TMMWebVC

-(id)init{
    self = [super init];
    if (self) {
        self.webView = nil;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSHTTPCookieStorage *cook = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    [cook setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    CGRect frame = self.view.frame;
    frame.origin.y = STATUS_BAR_HEIGHT;
    frame.size.height = kScreen_Height - STATUS_BAR_HEIGHT;
    
    self.webView = [[UIWebView alloc]initWithFrame:frame];
    self.webView.scrollView.bounces = NO;
    self.webView.delegate = self;
    [self.view addSubview:self.webView];
    [self.webView.scrollView setShowsHorizontalScrollIndicator:NO];
    [self.webView release];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:APP_URL]];
       [self.webView loadRequest:request];

    _bridge = [WebViewJavascriptBridge bridgeForWebView:self.webView webViewDelegate:self handler:^(id data, WVJBResponseCallback responseCallback) {
        DDLogInfo(@"%@ OK", data);
        responseCallback(data);
    }];
    
    [_bridge registerHandler:@"ObjcCallback" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSDictionary *dic = [NSDictionary dictionaryWithDictionary:data];
        NSArray *keyArr = [dic allKeys];
        if ([keyArr count] == 1)
        {
            NSString *szJSKey = [keyArr objectAtIndex:0];
            if ([szJSKey isEqualToString:@"phone"]) {
                
//                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"拨打电话?" message:[dic valueForKey:@"phone"] delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"拨打", nil];
//                [alertView show];
//                [alertView.rac_buttonClickedSignal subscribeNext:^(NSNumber *x) {
//                    if ([x isEqualToNumber:[NSNumber numberWithInteger:1]])
//                    {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel://%@",[dic valueForKey:@"phone"]]]];
//                    }
//                }];
//                [alertView release];
            }
            else if([szJSKey isEqualToString:@"QRCode"])
            {
                TMMQRCodeVc * rt = [[TMMQRCodeVc alloc]init:^(NSString *qrUrl) {
                    DDLogInfo(@"%@",qrUrl);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_bridge callHandler:@"JavascriptHandler" data:qrUrl responseCallback:^(id response) {}];
                    });
                }];
                [self presentViewController:rt animated:YES completion:nil];
                [rt release];
            }else if ([szJSKey isEqualToString:@"QRCodeResult"])
            {
                MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:self.view];
                [self.view addSubview:HUD];
                HUD.labelText = [dic valueForKey:@"QRCodeResult"];
                HUD.mode = MBProgressHUDModeText;
                
                [HUD showAnimated:YES whileExecutingBlock:^{
                    [NSThread sleepForTimeInterval:1];
                } completionBlock:^{
                    [HUD removeFromSuperview];  
                    [HUD release];  
                }];

                DDLogInfo(@"%@",[dic valueForKey:@"QRCodeResult"]);
            }
            else if ([szJSKey isEqualToString:@"Tips"])
            {
                MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:self.view];
                [self.view addSubview:HUD];
                HUD.labelText = [dic valueForKey:@"Tips"];
                HUD.mode = MBProgressHUDModeText;
                
                [HUD showAnimated:YES whileExecutingBlock:^{
                    [NSThread sleepForTimeInterval:1];
                } completionBlock:^{
                    [HUD removeFromSuperview];
                    [HUD release];
                }];

                DDLogInfo(@"%@",[dic valueForKey:@"Tips"]);
            }
        }
        
    }];
}

- (void)webViewHideBackgroundAndScrollBar:(UIWebView*)theView {
    theView.opaque = NO;
    theView.backgroundColor = [UIColor clearColor];
    
    for(UIView *view in theView.subviews) {
        if ([view isKindOfClass:[UIImageView class]]) {
            // to transparent
            [view removeFromSuperview];
        }
        
        if ([view isKindOfClass:[UIScrollView class]]) {
            UIScrollView *sView = (UIScrollView *)view;
            //to hide Scroller bar
            sView.showsVerticalScrollIndicator = NO;
            sView.showsHorizontalScrollIndicator = NO;
            
            for (UIView* shadowView in [sView subviews]){
                //to remove shadow
                if ([shadowView isKindOfClass:[UIImageView class]]) {
                    [shadowView setHidden:TRUE];
                }
            }
        }
    }
}

#pragma mark - UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    //    NSLog(@"Loading URL :%@",request.URL.absoluteString);
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
//    CustomURLCache *urlCache = (CustomURLCache *)[NSURLCache sharedURLCache];
//    [urlCache removeAllCachedResponses];
}


-(void) dealloc{
    [super dealloc];
    if (self.webView) {
        [self.webView release];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
