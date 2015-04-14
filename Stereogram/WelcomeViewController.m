//
//  WelcomeViewController.m
//  Stereogram
//
//  Created by Patrick Wallace on 13/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

#import "WelcomeViewController.h"
#import "PhotoStore.h"
#import "NSError_AlertSupport.h"

static UIWebView *cast_UIWebView(UIView *view) {
    NSCAssert([view isMemberOfClass:UIWebView.class], @"View %@ is not a UIWebView", view);
    return (UIWebView *)view;
}


@interface WelcomeViewController () {
    StereogramViewController *_stereogramViewController;
}

@end

@implementation WelcomeViewController
@synthesize photoStore = _photoStore;

#pragma mark Initialisers

-(instancetype) initWithNibName: (NSString *)nibNameOrNil
                         bundle: (NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:@"WelcomeView"
                          bundle: nibBundleOrNil];
    if (!self) { return nil; }
    _stereogramViewController = [[StereogramViewController alloc] initWithDelegate:self];
    return self;
}

-(id) initWithCoder: (NSCoder *)aDecoder {
    NSAssert(NO, @"init(coder:) has not been implemented");
    return nil;
}

#pragma mark Overrides

-(void)viewDidLoad {
    [super viewDidLoad];
        // Add a button for the camera on the right, and hide the back button on the left.
    UIBarButtonItem *takePhotoItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                                                                                   target:self
                                                                                   action:@selector(takePicture)];
    self.navigationItem.rightBarButtonItem = takePhotoItem;
    self.navigationItem.hidesBackButton = YES;
    
        // Give some text to display.
    UIWebView *webView = cast_UIWebView(self.view);
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSURL *welcomeFileURL = [mainBundle URLForResource:@"Welcome Text"
                                            withExtension:@"html"];
    NSAssert(welcomeFileURL, @"Bundle <%@> couldn't find file 'Welcome Text.html'", mainBundle);
    NSData *welcomeData = [NSData dataWithContentsOfURL:welcomeFileURL];
    NSAssert(welcomeData, @"Failed to load welcome data from bundle URL : %@", welcomeFileURL);
    [webView loadData:welcomeData
             MIMEType:@"text/html"
     textEncodingName:@"utf-8"
              baseURL:nil];
}

#pragma mark Callbacks

-(void) takePicture {
    [_stereogramViewController takePicture:self];
}

#pragma mark FullImageController delegate

-(void) fullImageViewController: (FullImageViewController *)controller
                  approvedImage: (UIImage *)image {
    NSDate *dateTaken = [NSDate date];
    NSError *error = nil;
    if (![_photoStore addImage:image
                     dateTaken:dateTaken
                         error:&error]) {
        [error showAlertWithTitle:@"Error saving photo" parentViewController:self];
    }
}

-(void)dismissedFullImageViewController:(FullImageViewController *)controller {
    [controller dismissViewControllerAnimated:NO completion:^{
            // Once the FullImageViewController is dismissed, check if we have now got some photos to display. If so, dismiss the welcome controller to reveal the photo controller, which should be the at the root of the controller hierarchy.
        if (_photoStore.count > 0) {
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
    }];
}


#pragma mark StereogramViewController delegate

-(void)stereogramViewController:(StereogramViewController *)controller
              createdStereogram:(UIImage *)stereogram {
    [controller reset];
    [controller dismissViewControllerAnimated:NO
                                   completion:^{
                                       [self showApprovalWindowForImage:stereogram];
                                   }];
}

-(void)stereogramViewControllerWasCancelled:(StereogramViewController *)controller {
    [controller dismissViewControllerAnimated:YES
                                   completion:nil];
}


#pragma mark Private Data

    // Called to present the image to the user, with options to accept or reject it.
    // If the user accepts, the photo is added to the photo store.
-(void) showApprovalWindowForImage: (UIImage *)image {
    FullImageViewController *fullImageViewController = [[FullImageViewController alloc] initWithImage:image
                                                                                          forApproval:YES
                                                                                             delegate:self];
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:fullImageViewController];
    navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:navigationController
                       animated:YES
                     completion:nil];
}
@end
