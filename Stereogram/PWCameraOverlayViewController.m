//
//  PWCameraOverlayViewController.m
//  Stereogram
//
//  Created by Patrick Wallace on 24/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import "PWCameraOverlayViewController.h"

@interface PWCameraOverlayViewController ()
{
    UIActivityIndicatorView *activityView;
}
@end

@implementation PWCameraOverlayViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:@"PWCameraOverlayView" bundle:nibBundleOrNil];
    if (self) {
        // Create the activity view, but don't attach it to anything yet.
        activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    }
    return self;
}

-(NSString *)helpText { return helpTextItem.title; }
-(void)setHelpText:(NSString *)text { helpTextItem.title = text; }

    // Return the frame used for the activity view, given the parent bounds and the child's size.
static CGRect activityFrame(CGRect parentBounds, CGSize activitySize)
{
    CGRect actFrame;
    actFrame.origin = CGPointMake((parentBounds.size.width / 2) - (activitySize.width / 2),
                                  (parentBounds.size.height / 2) - (activitySize.height / 2));
    actFrame.size = activitySize;
    return actFrame;
}

-(void)showWaitIcon:(BOOL) showIcon
{
    if(showIcon) {
        crosshair.hidden = YES;
        activityView.frame = activityFrame(self.view.bounds, activityView.bounds.size);
        [self.view addSubview:activityView];
        [activityView startAnimating];
    }
    else {
        crosshair.hidden = NO;
        [activityView stopAnimating];
        [activityView removeFromSuperview];
    }
}


- (IBAction)takePhoto:(id)sender
{
    NSAssert(self.imagePickerController, @"camera controller is nil.");
    [self.imagePickerController takePicture];
}

-(IBAction)cancel:(id)sender
{
    UIImagePickerController *picker = self.imagePickerController;
    NSAssert(picker && picker.delegate, @"camera controller is nil or has a nil delegate.");
    NSAssert([picker.delegate respondsToSelector:@selector(imagePickerControllerDidCancel:)],
             @"Delegate %@ doesn't respond to cancel message", picker.delegate);

    [picker.delegate imagePickerControllerDidCancel:picker];
}
@end
