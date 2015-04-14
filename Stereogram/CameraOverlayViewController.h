//
//  PWCameraOverlayViewController.h
//  Stereogram
//
//  Created by Patrick Wallace on 24/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CameraOverlayViewController : UIViewController

#pragma mark Interface Builder

@property (nonatomic, weak) IBOutlet UIBarButtonItem *helpTextItem;
@property (nonatomic, weak) IBOutlet UIImageView *crosshair;

    // I am replacing the standard buttons with my own, so I need to forward the messages to the image picker.
-(IBAction) takePhoto: (id)sender;
-(IBAction) cancel: (id)sender;

#pragma mark Properties

@property (nonatomic, strong) UIImagePickerController *imagePickerController;

    // Set the help text to display to the user.
@property (nonatomic, copy) NSString *helpText;

#pragma mark Methods

    // if showIcon, Trigger a wait icon as the device is processing in the background. Otherwise hide the icon.
-(void)showWaitIcon:(BOOL) showIcon;

@end
