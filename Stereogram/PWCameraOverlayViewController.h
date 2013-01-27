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
    __weak IBOutlet UIButton *takePhotoButton;
}
@property IBOutlet UITextView __weak * instructionLabel;
@property UIImagePickerController *imagePickerController;


    // I am replacing the standard button with my own, so I need to forward the message to the
    // image picker.
- (IBAction)takePhoto:(id)sender;

@end
