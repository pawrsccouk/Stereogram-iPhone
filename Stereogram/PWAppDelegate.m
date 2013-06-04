//
//  PWAppDelegate.m
//  Stereogram
//
//  Created by Patrick Wallace on 20/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import "PWAppDelegate.h"
#import "PWPhotoViewController.h"
#import "PWPhotoStore.h"
#import "NSError_AlertSupport.h"

@implementation PWAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    
        // Perform some setup on the photo store (such as reading the filenames of available photos etc).
    NSError *error = [PWPhotoStore setupStore];
    if(error)
        [error showAlertWithTitle:@"Startup error"];
    

    PWPhotoViewController *photoVC = [[PWPhotoViewController alloc] init];
    UINavigationController *rootVC = [[UINavigationController alloc] initWithRootViewController:photoVC];
    self.window.rootViewController = rootVC;
    
    self.window.backgroundColor = [UIColor whiteColor];
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
        // Ask the system for a little more time to save the data.  It creates a task-id and gives us a few seconds to save.
        // Then it calls the expiration handler, which must finish the task. If not, the app is killed.
        
    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
            // This is called when time runs out for your background task.
        NSLog(@"Background task terminated early.");
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    
        // This starts the task on a background thread. Here we save the data.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSError *error = [[PWPhotoStore sharedStore] saveProperties];
            // Can't inform the user here, as the app has been replaced. Do we present it for them when the app restores?
        if(error)
            NSLog(@"Error saving the image properties. Error %@ user info %@", error, error.userInfo);
        
        NSLog(@"Background task save complete.");
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    });
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
