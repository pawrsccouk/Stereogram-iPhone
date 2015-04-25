//
//  PWCameraOverlayViewController.h
//  Stereogram
//
//  Created by Patrick Wallace on 24/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

@import UIKit;
@class UIImagePickerController;

/*!
 * View controller presenting a view which will be displayed over the camera view and will hold our crosshairs and custom icons.
 */

@interface CameraOverlayViewController : UIViewController

#pragma mark Properties

/*!
 * Help text to display to the user. 
 */
@property (nonatomic, copy) NSString *helpText;

#pragma mark Methods

/*!
 * Show or hide a wait icon over this view.  This should be running when the view is running a long operation on another queue.
 */
-(void)showWaitIcon: (BOOL)showIcon;

/*!
 * Initialize this object.
 *
 * @param parentController The picker controller window our view needs to appear in front of.  
 * We need to forward the photo-taking actions to this view.
 */
-(instancetype)initWithPickerController: (UIImagePickerController *)parentController NS_DESIGNATED_INITIALIZER;

@end
