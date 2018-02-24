//
//  AppDelegate.m
//  PhotosMaker
//
//  Created by Darsky on 2018/2/6.
//  Copyright © 2018年 Darsky. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"


@interface AppDelegate ()

@property (strong, nonatomic) ViewController *viewController;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    //
    //
    //                            _ooOoo_
    //                           o8888888o
    //                           88" . "88
    //                           (| -_- |)
    //                            O\ = /O
    //                        ____/`---'\____
    //                      .   ' \\| |// `.
    //                       / \\||| : |||// \
    //                     / _||||| -:- |||||- \
    //                       | | \\\ - /// | |
    //                     | \_| ''\---/'' | |
    //                      \ .-\__ `-` ___/-. /
    //                   ___`. .' /--.--\ `. . __
    //                ."" '< `.___\_<|>_/___.' >'"".
    //               | | : `- \`.;`\ _ /`;.`/ - ` : | |
    //                 \ \ `-. \_ __\ /__ _/ .-` / /
    //         ======`-.____`-.___\_____/___.-`____.-'======
    //                            `=---='
    //
    //         .............................................
    //
    //                  佛祖镇楼              BUG辟易
    //
    //
    //          佛曰:
    //                  写字楼里写字间， 写字间里程序员；
    //                  程序人员写程序， 又拿程序换酒钱。
    //                  酒醒只在网上坐， 酒醉还来网下眠；
    //                  酒醉酒醒日复日， 网上网下年复年。
    //                  但愿老死电脑间， 不愿鞠躬老板前；
    //                  奔驰宝马贵者趣， 公交自行程序员。
    //                  别人笑我忒疯癫， 我笑自己命太贱；
    //                  不见满街漂亮妹， 哪个归得程序员？
    //
    //

    self.window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    
    self.viewController = [[ViewController alloc] initWithNibName:@"ViewController"
                                                          bundle:nil];
    
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:self.viewController];
    [self.window resignKeyWindow];
    [self.window makeKeyAndVisible];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
