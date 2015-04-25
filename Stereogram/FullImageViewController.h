//
//  PWFullImageViewController.h
//  Stereogram
//
//  Created by Patrick Wallace on 23/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

@import UIKit;
@class FullImageViewController, Stereogram;

/*! Result of the user's review of the image. Do they want to keep it or delete it.
 * @constant ApprovalResult_Approved  User wants to keep this image.
 * @constant ApprovalResult_Discarded User wants to discard this image.
 */
typedef enum ApprovalResults {
        /*! User wants to keep this image. */
    ApprovalResult_Approved,
        /*! User wants to discard this image. */
    ApprovalResult_Discarded
} ApprovalResults;



/*! 
 * Protocol allowing FullImageViewController delegates to receive messages from the controller.
 *
 * The delegate must implement dismissedFullImageViewController: to remove the controller from the view hierarchy.
 * There are also optional methods for noting if the user changed properties on the stereogram or if the user accepted or rejected one.
 */
@protocol FullImageViewControllerDelegate <NSObject>
    
/*!
 * Called when the user has requested the controller be closed.
 *
 * On receipt of this message, the delegagte must remove the view controller from the stack.
 */
-(void) dismissedFullImageViewController: (FullImageViewController *)controller;

@optional

/*!
 * Called if the controller is in Approval mode when the user has approved or rejected a stereogram.
 * 
 * @param controller The view controller that sent this message.
 * @param stereogram The stereogram this controller is looking at.
 * @param result     Whether the user wants to accept or reject this stereogram.
 */
-(void) fullImageViewController: (FullImageViewController *)controller
            approvingStereogram: (Stereogram *)stereogram
                         result: (ApprovalResults)result;
    
/*!
 * Called if the controller is viewing a sterogram, and the stereogram changed.
 *
 * This will be called in both approval mode and regular viewing mode.
 *
 * @param controller The view controller that sent this message.
 * @param stereogram The stereogram this controller is looking at.
 * @param userInfo   Arbitrary data the caller can provide which will be available to the callback messages on the delegate.
 */
-(void) fullImageViewController: (FullImageViewController *)controller
              amendedStereogram: (Stereogram *)stereogram
                       userInfo: (id)userInfo;

@end

#pragma mark -

/*!
 * View controller which presents a view to display a single image at full size, and allow scrolling and some simple image modifications.
 */

@interface FullImageViewController : UIViewController <UIScrollViewDelegate>

/*!
 * Delegate with callbacks if the user approved, rejected or modified the image.
 */
@property (nonatomic, copy) id<FullImageViewControllerDelegate> delegate;

/*!
 * Convenience Initializer. Initialise the image view to display the given image.
 *
 * @param stereogram The stereogram to display.
 * @param forApproval If this is YES, the view gets a 'Keep' button; if pressed, should copy the image to permanent storage.
 * @param delegate    A default delegate to send notification messages to.
 */

-(instancetype) initWithStereogram: (Stereogram *)stereogram
                       forApproval: (BOOL)forApproval
                          delegate: (id<FullImageViewControllerDelegate>)delegate;

/*!
 * Convenience initialiser. Open in normal mode, viewing the index at the selected index path.
 *
 * @param stereogram The stereogram to display.
 * @param delegate   A default delegate to send notification messages to.
 * @param userInfo   Arbitrary object which will be passed back to the delegate. For the caller to associate properties.
 */

-(instancetype) initWithStereogram: (Stereogram *)stereogram
                          delegate: (id<FullImageViewControllerDelegate>)delegate
                          userInfo: (id)userInfo;


@end
