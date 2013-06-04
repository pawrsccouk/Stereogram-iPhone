//
//  PWCameraOverlayViewController.h
//  Stereogram
//
//  Created by Patrick Wallace on 24/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import <UIKit/UIKit.h>

// For the moment, this does nothing except load the view provided in the xib.
// Later I'll add controls to the camera overlay and it'll become more important.

@interface PWCameraOverlayViewController : UIViewController
{
//    __weak IBOutlet UIButton *takePhotoButton;
    __weak IBOutlet UIBarButtonItem *helpTextItem;
//    __weak IBOutlet UITextView * instructionLabel;
    __weak IBOutlet UIImageView * crosshair;
}
@property UIImagePickerController *imagePickerController;

    // Set the help text to display to the user.
@property (nonatomic, copy) NSString *helpText;

    // if showIcon, Trigger a wait icon as the device is processing in the background.
    // otherwise hide the icon.
-(void)showWaitIcon:(BOOL) showIcon;

    // I am replacing the standard buttons with my own, so I need to forward the messages to the
    // image picker.
- (IBAction)takePhoto:(id)sender;
-(IBAction)cancel:(id)sender;
@end
