//
//  StereogramViewController.m
//  Stereogram
//
//  Created by Patrick Wallace on 13/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>
#import "StereogramViewController.h"
#import "CameraOverlayViewController.h"
#import "ImageManager.h"
#import "UIImage+Resize.h"
#import "NSError_AlertSupport.h"
#import "Stereogram.h"
#import "PhotoStore.h"

    /// This controller can be in multiple states. Capture these here.
typedef enum State {
        /// The photo process has not started yet.
    Ready,
        /// We are currently taking the first photo
    TakingFirstPhoto,
        /// We are currently taking the second photo. firstPhoto contains the first photo we took
    TakingSecondPhoto,
        /// We have taken both photos and composited them into a stereogram.
    Complete
} State;

inline static NSString *cast_NSString(CFStringRef stringRef) { return (__bridge NSString *)stringRef; }
inline static UIImage *imageFromPickerInfoDict(NSDictionary *infoDict);
inline static NSString *stringFromState(State state);

@interface StereogramViewController () {
    State _state;
    UIImage *_firstPhoto;
    Stereogram *_stereogram;
    CameraOverlayViewController *_cameraOverlayController;
    UIImagePickerController *_pickerController;
    PhotoStore *_photoStore;
}
@end



@implementation StereogramViewController
@synthesize parentViewController = _parentController, delegate = _delegate;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    NSAssert(_state == Ready, @"viewDidLoad invalid state of %ld", (long)_state);
}

- (instancetype) initWithPhotoStore: (PhotoStore *)photoStore
                           delegate: (id<StereogramViewControllerDelegate>)delegate {
    self = [super init];
    if (!self) { return nil; }
    _state = Ready;
    _firstPhoto = nil;
    _stereogram = nil;
    _delegate = delegate;
    _photoStore = photoStore;
    return self;
}

    // The stereogram the user has taken, if any.
- (Stereogram *)stereogram {
    [self assertState];
    return _state == Complete ? _stereogram : nil;
}


-(void) assertState {
    switch (_state) {
        case Complete:
            NSAssert(_stereogram, @"_stereogram must be valid in state Complete.");
            break;
        case TakingSecondPhoto:
            NSAssert(_firstPhoto, @"_firstPhoto must be valid in state TakingSecondPhoto");
            break;
        default:
            break;
    }
}

-(void) reset {
    _state = Ready;
    _cameraOverlayController.helpText = @"Take the first photo";
    _firstPhoto = nil;
    _stereogram = nil;
}

-(void) takePicture: (UIViewController *)parentController {
    NSAssert(_state == Ready, @"takePicture: invalid state is %ld, should be Ready (%ld)", (long)_state, (long)Ready);
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"No camera"
                                                            message:@"This device does not have a camera attached"
                                                           delegate:nil
                                                  cancelButtonTitle:@"Close"
                                                  otherButtonTitles:nil];
        [alertView show];
        return;
    }
    
    [self assertState];
    switch (_state) {
        case Ready:
        case Complete: {
            _parentController = parentController;
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            _pickerController = picker;
            
            picker.sourceType = UIImagePickerControllerSourceTypeCamera;
            picker.mediaTypes = @[cast_NSString(kUTTypeImage)];  // This is the default.
            picker.delegate   = self;
            picker.showsCameraControls = NO;

                // Set up a custom overlay view for the camera. Ensure our custom view frame fits within the camera view's frame.
            if (!_cameraOverlayController) {
                _cameraOverlayController= [[CameraOverlayViewController alloc] initWithPickerController:picker];
            }
            _cameraOverlayController.view.frame = picker.view.frame;
            picker.cameraOverlayView = _cameraOverlayController.view;
            _cameraOverlayController.helpText = @"Take the first photo";
            [_parentController presentViewController:picker
                                            animated:YES
                                          completion:nil];
            _state = TakingFirstPhoto;
            if ([_delegate respondsToSelector:@selector(stereogramViewController:takingPhoto:)]) {
                [_delegate stereogramViewController:self takingPhoto:1];
            }
            break;
        }
            
        case TakingFirstPhoto:
        case TakingSecondPhoto:
            NSAssert(NO, @"State %ld was invalid. Another photo operation already in progress.", (long)_state);
            break;
            
        default:
            NSAssert(NO, @"Unknown state %ld", (long)_state);
            break;
    }
}

-(void)dismissViewControllerAnimated: (BOOL)flag
                          completion:(void (^)(void))completion {
    if (_pickerController) {
        [_pickerController dismissViewControllerAnimated:flag completion:completion];
    }
    _pickerController = nil;
}


#pragma mark Image Picker Delegate

-(void) imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self assertState];
    
    switch (_state) {
        case TakingFirstPhoto:
            _state = TakingSecondPhoto;
            _firstPhoto = imageFromPickerInfoDict(info);
            _cameraOverlayController.helpText = @"Take the second photo";
            if ([_delegate respondsToSelector:@selector(stereogramViewController:takingPhoto:)]) {
                [_delegate stereogramViewController:self takingPhoto:2];
            }
            break;
            
        case TakingSecondPhoto: {
            UIImage *secondPhoto = imageFromPickerInfoDict(info);
            [_cameraOverlayController showWaitIcon:YES];
                // Dispatch the stereogram creation on to a background queue and tell it to dispatch onto the main queue when it completes.
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                NSError *error = nil;
                _stereogram = [_photoStore createStereogramFromLeftImage:_firstPhoto
                                                              rightImage:secondPhoto
                                                                   error:&error];
                if (_stereogram) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        _state = Complete;
                            //picker.dismissViewControllerAnimated(false, completion: nil)
                        [_cameraOverlayController showWaitIcon:NO];
                        [_delegate stereogramViewController:self
                                          createdStereogram:_stereogram];
                    });
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        [error showAlertWithTitle:@"Error creating the stereogram image"
                             parentViewController:self.parentViewController];
                        _state = Ready;
                    });
                }
            });
            break;
        }
        default:
            NSAssert(NO, @"Inconsistent state of %ld, should be TakingFirstPhoto or TakingSecondPhoto", (long)_state);
            break;
    }
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    _state = Ready;
    [self.delegate stereogramViewControllerWasCancelled:self];
}

- (NSString *)description {
    NSString *parent = [super description];
    NSString *stateDescription = stringFromState(_state);
    return [NSString stringWithFormat:@"%@ <state = %@>", parent, stateDescription];
}

@end

    /// Get the edited photo from the info dictionary if the user has edited it. If there is no edited photo, get the original photo. If there is no original photo, terminate with an error.
inline static UIImage *imageFromPickerInfoDict(NSDictionary *infoDict) {
    UIImage *photo = infoDict[UIImagePickerControllerEditedImage];
    if (photo) {
        return photo;
    }
    return infoDict[UIImagePickerControllerOriginalImage];
}

    /// Human-readable description of the current state.
inline static NSString *stringFromState(State state) {
    switch (state) {
        case Ready:             return @"Ready";
        case TakingFirstPhoto:  return @"TakingFirstPhoto";
        case TakingSecondPhoto: return @"TakingSecondPhoto";
        case Complete:          return @"Complete";
        default:                return [NSString stringWithFormat:@"Unknown state: %ld", (long)state];
    }
}
