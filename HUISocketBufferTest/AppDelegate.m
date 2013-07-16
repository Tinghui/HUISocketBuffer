//
//  AppDelegate.m
//  HUISocketBufferTest
//
//  Created by ZhangTinghui on 13-7-16.
//  Copyright (c) 2013年 ZhangTinghui. All rights reserved.
//

#import "AppDelegate.h"

#import "ViewController.h"
#import "HUISocketBuffer.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    HUISocketBuffer *buffer = [HUISocketBuffer buffer];
    [buffer enqueueByte:'A'];
    [buffer enqueueBytes:"CDEFG" withLength:5];
    [buffer enqueueUInt16:18];
    [buffer enqueueUInt32:2332];
    [buffer enqueueUInt64:3444];
    
    NSString *string = @"HUISocketBuffer测试";
    [buffer enqueueBytes:[string UTF8String] withLength:strlen([string UTF8String])];
    
    NSLog(@"enqueued data[%@]", [buffer bufferData]);
    
    HUISocketBuffer *buffer2 = [HUISocketBuffer bufferWithData:[buffer bufferData]];
    NSLog(@"%c", [buffer2 dequeueByte]);
    
    void *tb = malloc(6);
    NSAssert(tb != NULL, @"error");
    memset(tb, 0, 6);
    [buffer2 dequeueToBuffer:tb withLength:5];
    NSLog(@"%s", tb);
    
    NSLog(@"%d", [buffer2 dequeueUInt16]);
    NSLog(@"%lu", [buffer2 dequeueUInt32]);
    NSLog(@"%llu", [buffer2 dequeueUInt64]);
    NSLog(@"%@", [buffer2 dequeueUTF8StringWithLength:strlen([string UTF8String])]);
    
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.viewController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
