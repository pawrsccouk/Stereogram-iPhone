//
//  StereogramViewController.h
//  Stereogram
//
//  Created by Patrick Wallace on 13/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

@import UIKit;
@class StereogramViewController, Stereogram, PhotoStore;

/*!
 * Delegate for a stereogram view controller. The mandatory delegate is responsible for dismissing the delegate once it is finished.
 * as well as being notified during the photo-taking process.
 */
@protocol StereogramViewControllerDelegate <NSObject>

/*!
 * Called when the stereogram has been taken. 
 * 
 * Here you need to save the image and dismiss the view controller.
 * 
 * @param controller The view controller sending this message.
 * @param createdStereogrm The new stereogram object this controller has created.
 */
-(void) stereogramViewController: (StereogramViewController *)controller
               createdStereogram: (Stereogram *)createdStereogram;

/*!
 * Called if the user cancels the view controller and doesn't want to create a stereogram.
 *
 * The delegate must dismiss the view controller here.
 *
 * @param controller The view controller sending this message.
 */
-(void) stereogramViewControllerWasCancelled: (StereogramViewController *)controller;

@optional

/*!
 * Triggered when the controller starts displaying the camera view. 
 *
 * Will be sent twice (assuming the user doesn't cancel). Once for the first photo and once for the second.
 * 
 * @param controller  The view controller sending this message.
 * @param photoNumber Will be 1 or 2 depending on which photo is being taken.
 */
-(void) stereogramViewController: (StereogramViewController *)controller
                     takingPhoto: (NSUInteger *)photoNumber;
@end

#pragma mark -



/*!
 * View controller which will present a modified camera view to the user, guide that user to take the photos making up a steregram
 * and then return the completed stereogram to the caller via a delegate message.
 */
@interface StereogramViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

/*! 
 * The stereogram the user has taken, if any.
 * 
 * Call 'reset' to clear the stereogram out and avoid memory pressure.
 */
@property (nonatomic, readonly) Stereogram *stereogram;

/*!
 * The delegate object for this controller.
 */
@property (nonatomic, unsafe_unretained) id<StereogramViewControllerDelegate> delegate;


/*!
 * Convenience Initializer.  
 *
 * @param photoStore The photo store. The new stereogram will be added to this photo-store.
 * @param delegate   The delegate to send messages to.
 */
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
