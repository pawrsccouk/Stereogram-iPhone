//
//  PWCameraOverlayViewController.m
//  Stereogram
//
//  Created by Patrick Wallace on 24/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import "PWCameraOverlayViewController.h"

@implementation PWCameraOverlayViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:@"PWCameraOverlayView" bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(NSString *)helpText { return helpTextItem.title; }
-(void)setHelpText:(NSString *)text { helpTextItem.title = text; }

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
