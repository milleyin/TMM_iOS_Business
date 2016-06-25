//
//  AppDelegate.m
//  TianMM
//
//  Created by cocoa on 15/9/4.
//  Copyright (c) 2015年 cocoa. All rights reserved.
//

#import "AppDelegate.h"
#import "TMMWebVC.h"

NSString * const DefaultStoredVersionCheckDate = @"App_Version_Check_Store";
NSString * const DefaultSkippedVersion = @"DefaultSkippedVersion_Store";

@interface AppDelegate ()

@property (assign ,nonatomic) TMMWebVC *webVC;
@property (nonatomic, assign) NSDate *lastAppVersionCheckOnDate;

@end

@implementation AppDelegate

- (void)CheckAppVersion{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        _lastAppVersionCheckOnDate = [[NSUserDefaults standardUserDefaults] objectForKey:DefaultStoredVersionCheckDate];
        if (![self lastAppVersionCheckOnDate]) {
            self.lastAppVersionCheckOnDate = [NSDate date];
        }else{
            NSCalendar *currentCalendar = [NSCalendar currentCalendar];
            NSDateComponents *components = [currentCalendar components:NSCalendarUnitDay
                                                              fromDate:[self lastAppVersionCheckOnDate]
                                                                toDate:[NSDate date]
                                                               options:0];
            if ([components day] < 3) {
                return;
            }
        }
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        [configuration setRequestCachePolicy:NSURLRequestReloadIgnoringCacheData];
        NSURLSessionDataTask *task = [[NSURLSession sessionWithConfiguration:configuration] dataTaskWithURL:[NSURL URLWithString:APPSTORE_UPDATE_URL]
                                                                                          completionHandler:^(NSData *  data, NSURLResponse *  response, NSError *  error)
                                      {
                                          if ([(NSHTTPURLResponse*)response statusCode] == 200 && error == nil) {
                                              NSDictionary *resultJSON = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                                              if ([resultJSON count] > 0) {
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      
                                                      if ([[resultJSON objectForKey:@"resultCount"] integerValue] == 1) {
                                                          NSArray *verArr = [resultJSON objectForKey:@"results"];
                                                          NSDictionary *verDic = [verArr objectAtIndex:0];
                                                          NSString *currentAppStoreVersion = [verDic objectForKey:@"version"];
                                                          
                                                          if (![[[NSUserDefaults standardUserDefaults] objectForKey:DefaultSkippedVersion] isEqualToString:currentAppStoreVersion]) {
                                                              NSArray *oldVersionComponents = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] componentsSeparatedByString:@"."];
                                                              
                                                              NSArray *newVersionComponents = [currentAppStoreVersion componentsSeparatedByString: @"."];
                                                              
                                                              if ([oldVersionComponents count] == 3 && [newVersionComponents count] == 3) {
                                                                  if ([newVersionComponents[0] integerValue] > [oldVersionComponents[0] integerValue] ||
                                                                      ([newVersionComponents[0] integerValue] == [oldVersionComponents[0] integerValue] &&
                                                                       [newVersionComponents[1] integerValue] > [oldVersionComponents[1] integerValue]) ||
                                                                      ([newVersionComponents[0] integerValue] == [oldVersionComponents[0] integerValue] &&
                                                                       [newVersionComponents[1] integerValue] == [oldVersionComponents[1] integerValue] &&
                                                                       [newVersionComponents[2] integerValue] > [oldVersionComponents[2] integerValue]))
                                                                  {
                                                                      self.lastAppVersionCheckOnDate = [NSDate date];
                                                                      [[NSUserDefaults standardUserDefaults] setObject:[self lastAppVersionCheckOnDate] forKey:DefaultStoredVersionCheckDate];
                                                                      [[NSUserDefaults standardUserDefaults] synchronize];
                                                                      
                                                                      UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"田觅觅-商家端" message:[NSString stringWithFormat:@"检测到新的 %@ 版本，是否更新？",currentAppStoreVersion] delegate:nil cancelButtonTitle:@"跳过此版本"otherButtonTitles:@"去更新", nil];
                                                                      [[alertView rac_buttonClickedSignal] subscribeNext:^(NSNumber *indexNumber) {
                                                                          if ([indexNumber intValue] == 0) {
                                                                              [[NSUserDefaults standardUserDefaults] setObject:currentAppStoreVersion forKey:DefaultSkippedVersion];
                                                                              [[NSUserDefaults standardUserDefaults] synchronize];
                                                                          } else {
                                                                              [[UIApplication sharedApplication] openURL:[NSURL URLWithString:APPSTORE_URL]];
                                                                          }
                                                                      }];
                                                                      [alertView show];
                                                                      [alertView release];
                                                                  }
                                                              }
                                                          }
                                                      }
                                                  });
                                              }
                                          }
                                      }];
        [task resume];
    });
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    NSURLCache *sharedCache = [[[NSURLCache alloc] initWithMemoryCapacity: 4*1024*1024 diskCapacity:32*1024*1024 diskPath:@"nsurlcache"] autorelease];
    [NSURLCache setSharedURLCache:sharedCache];
    
    self.webVC = [[TMMWebVC alloc]init];
    self.window.rootViewController = self.webVC;
    [self.window makeKeyAndVisible];
    
    [self CheckAppVersion];
    
    return YES;
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}
//- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session{
//    DDLogDebug(@"%@",session.configuration.identifier);
//}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
//    GBDeviceInfo *deviceInfo = [GBDeviceInfo deviceInfo];
//    if (deviceInfo.deviceVersion.major <8) {
//        __block UIBackgroundTaskIdentifier bgTask;// 后台任务标识
//        
//        // 结束后台任务
//        void (^endBackgroundTask)() = ^(){
//            [application endBackgroundTask:bgTask];
//            bgTask = UIBackgroundTaskInvalid;
//        };
//        
//        bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
//            endBackgroundTask();
//        }];
//        
//        double start_time = application.backgroundTimeRemaining;
//        
//        [self CheckContentUpdate];
//        dispatch_semaphore_wait(_semaphore, dispatch_time(DISPATCH_TIME_NOW, 9*60*NSEC_PER_SEC));
//        double done_time = application.backgroundTimeRemaining;
//        double spent_time = start_time - done_time;
//        NSLog(@"后台完成，耗时: %f秒", spent_time);
//        endBackgroundTask();
//    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void) dealloc{
    [super dealloc];
    [self.webVC release];
}

@end
