//
//  StereogramViewController.h
//  Stereogram
//
//  Created by Patrick Wallace on 13/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

#import <UIKit/UIKit.h>
@class StereogramViewController, Stereogram, PhotoStore;


@protocol StereogramViewControllerDelegate <NSObject>

    /// Called when the stereogram has been taken. Here you need to save the image and dismiss the view controller.
-(void) stereogramViewController: (StereogramViewController *)controller
               createdStereogram: (Stereogram *)stereogram;

    /// Called if the user cancels the view controller and doesn't want to create a stereogram.  The delegate must dismiss the view controller here.
-(void) stereogramViewControllerWasCancelled: (StereogramViewController *)controller;

@optional

    /// Triggered when the controller starts displaying the camera view. photoNumber will be 1 or 2 depending on which photo is being taken.
-(void) stereogramViewController: (StereogramViewController *)controller
                     takingPhoto: (NSUInteger *)photoNumber;
@end

#pragma mark -

@interface StereogramViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

/*! The stereogram the user has taken, if any. 
 * 
 * Call 'reset' to clear the stereogram out and avoid memory pressure.
 */
@property (nonatomic, readonly) Stereogram *stereogram;


@property (nonatomic, unsafe_unretained) id<StereogramViewControllerDelegate> delegate;

-(instancetype) initWithPhotoStore: (PhotoStore *)photoStore
                          delegate: (id<StereogramViewControllerDelegate>)delegate;

/*!
 * Reset the controller back to the default state. 
 *
 * If we stored a stereogram from a previous run, it will be destroyed here, so take a copy first.
 */

-(void) reset;

    /*!
     * Display the camera above the specified view controller, take the user through the specified steps
     * to produce a stereogram image and put the result in self.stereogram.
     *
     * @param parentViewController The view controller presenting this one.
     */

-(void) takePicture: (UIViewController *)parentViewController;



@end
