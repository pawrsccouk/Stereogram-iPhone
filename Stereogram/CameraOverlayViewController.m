//
//  PWCameraOverlayViewController.m
//  Stereogram
//
//  Created by Patrick Wallace on 24/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import "CameraOverlayViewController.h"

@interface CameraOverlayViewController () {
    UIActivityIndicatorView *_activityView;
    UIImagePickerController *_parentPicker;
}

#pragma mark Interface Builder

@property (nonatomic, weak) IBOutlet UIBarButtonItem *helpTextItem;
@property (nonatomic, weak) IBOutlet UIImageView *crosshair;

@end



#pragma mark -



@implementation CameraOverlayViewController

-(instancetype) initWithPickerController:(UIImagePickerController *)parentController {
    self = [super initWithNibName:@"CameraOverlayView"
                           bundle:nil];
    if (self) {
            // Create the activity view, but don't attach it to anything yet.
        _activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _parentPicker = parentController;
    }
    return self;
}

-(NSString *) helpText {
    return self.helpTextItem.title;
}

-(void) setHelpText: (NSString *)text {
    self.helpTextItem.title = text;
}

-(void) showWaitIcon: (BOOL)showIcon {
    
        // Return the frame used for the activity view, given the parent bounds and the child's size.
    if(showIcon) {
        self.crosshair.hidden = YES;
        _activityView.frame = (CGRect) {
            .origin = CGPointMake((self.view.bounds.size.width  / 2) - (_activityView.bounds.size.width  / 2),
                                  (self.view.bounds.size.height / 2) - (_activityView.bounds.size.height / 2)),
            .size = _activityView.bounds.size
        };
        [self.view addSubview:_activityView];
        [_activityView startAnimating];
    }
    else {
        self.crosshair.hidden = NO;
        [_activityView stopAnimating];
        [_activityView removeFromSuperview];
    }
}

#pragma mark Interface Builder

-(IBAction) takePhoto: (id)sender {
    NSAssert(_parentPicker, @"camera controller is nil.");
    [_parentPicker takePicture];
}

-(IBAction) cancel: (id)sender {
    NSAssert(_parentPicker && _parentPicker.delegate, @"camera controller %@ is nil or has a nil delegate.", _parentPicker);
    NSAssert([_parentPicker.delegate respondsToSelector:@selector(imagePickerControllerDidCancel:)],
             @"Delegate %@ doesn't respond to cancel message", _parentPicker.delegate);

    [_parentPicker.delegate imagePickerControllerDidCancel:_parentPicker];
}
@end

