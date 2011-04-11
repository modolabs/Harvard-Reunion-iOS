//
//  apitestcase3AppDelegate.m
//  apitestcase3
//
//  Copyrights / Disclaimer
//  Copyright 2011, Bump Technologies, Inc. All rights reserved.
//  Use of the software programs described herein is subject to applicable
//  license agreements and nondisclosure agreements. Unless specifically
//  otherwise agreed in writing, all rights, title, and interest to this
//  software and documentation remain with Bump Technologies, Inc. Unless
//  expressly agreed in a signed license agreement, Bump Technologies makes
//  no representations about the suitability of this software for any purpose
//  and it is provided "as is" without express or implied warranty.
//
//  Copyright (c) 2011 Bump Technologies Inc. All rights reserved.
//  
//

#import "apitestcase3AppDelegate.h"
#import "apitestcase3ViewController.h"
#import "BumpAPI.h"

@implementation apitestcase3AppDelegate

@synthesize window;
@synthesize viewController;


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    // Override point for customization after application launch.

    // Add the view controller's view to the window and display.
    [self.window addSubview:viewController.view];
    [self.window makeKeyAndVisible];

    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
	[[BumpAPI sharedInstance] endSession];
	NSLog(@"App Entered backgournd");
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
	[[BumpAPI sharedInstance] requestSession];
	NSLog(@"App retunred from backgorund");
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc {
    [viewController release];
    [window release];
    [super dealloc];
}


@end
