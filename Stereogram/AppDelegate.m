//
//  PWAppDelegate.m
//  Stereogram
//
//  Created by Patrick Wallace on 20/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import "AppDelegate.h"
#import "PhotoViewController.h"
#import "PhotoStore.h"
#import "PWAlertView.h"
#import "PWActionSheet.h"
#import "NSError_AlertSupport.h"
#import "ErrorData.h"
#import "WelcomeViewController.h"

@interface AppDelegate () {
    PhotoStore *_photoStore;
}

@end

@implementation AppDelegate

-(BOOL)           application: (UIApplication *)application
didFinishLaunchingWithOptions: (NSDictionary *)launchOptions {
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    if (self.window) {
        
            // Initialise the photo store, and capture any errors it returns.
        NSError *error = nil;
        _photoStore = [[PhotoStore alloc] init:&error];
        if (_photoStore) {
            
            PhotoViewController *photoViewController = [[PhotoViewController alloc] init];
            photoViewController.photoStore = _photoStore;
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:photoViewController];
            
                // If photoStore is empty after creation, push a special view controller which doesn't have a collection view, but instead has some welcome text. When the user takes the first photo, pop that welcome view controller to reveal the standard collection view.
            if (_photoStore.count == 0) {
                WelcomeViewController *welcomeViewController = [[WelcomeViewController alloc] init];
                welcomeViewController.photoStore = _photoStore;
                [navigationController pushViewController:welcomeViewController
                                                animated:NO];
            }
            
            self.window.rootViewController = navigationController;
            self.window.backgroundColor = [UIColor whiteColor];

        } else {  // PhotoStore init failed.
            [self terminateWithError:error];
        }
        [self.window makeKeyAndVisible];
    }
    return self.window != nil;
}


-(void) terminateWithError: (NSError *)error {
    if (!error) {
        error = [NSError errorWithDomain: kErrorDomainPhotoStore
                                    code: ErrorCode_CouldntCreateSharedStore
                                userInfo: @{ NSLocalizedDescriptionKey : @"Unknown error"}];
    }
    PWAlertView *alertView = [[PWAlertView alloc] initWithTitle:@""
                                                        message:error.localizedDescription
                                                 preferredStyle:UIAlertControllerStyleAlert];
    PWAction *closeAction = [PWAction actionWithTitle:@"Terminate"
                                              handler:^(PWAction *action) {
                                                  NSLog(@"Error %@ caused this application to terminate.", error);
                                                  abort();
                                              }];
    [alertView addAction:closeAction];
    [alertView show];
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
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
        
            // TODO: Implement save-on-background.
//        NSError *error = nil;
//        if (![_photoStore saveProperties:&error]) {
//            // Can't inform the user here, as the app has been replaced. Do we present it for them when the app restores?
//            NSLog(@"Error saving the image properties. Error %@ user info %@", error, error.userInfo);
//        }
//        NSLog(@"Background task save complete.");
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
