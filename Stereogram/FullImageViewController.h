//
//  PWFullImageViewController.h
//  Stereogram
//
//  Created by Patrick Wallace on 23/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import <UIKit/UIKit.h>
@class FullImageViewController, Stereogram;

    /// Result of the user's review of the image. Do they want to keep it or delete it.
typedef NS_ENUM(NSInteger, ApprovalResults) {
        /// User wants to keep this image.
    ApprovalResult_Approved,
        /// User wants to discard this image.
    ApprovalResult_Discarded
};

@protocol FullImageViewControllerDelegate <NSObject>
    
         // Called when the user has requested the controller be closed. On receipt of this message, the delegagte must remove the view controller from the stack.
-(void) dismissedFullImageViewController: (FullImageViewController *)controller;

@optional

    /// Called if the controller is in Approval mode when the user has approved or rejected a stereogram.
-(void) fullImageViewController: (FullImageViewController *)controller
            approvingStereogram: (Stereogram *)stereogram
                         result: (ApprovalResults)result;
    
    /// Called if the controller is viewing a sterogram, and the stereogram changed.
    // This will be called in both approval mode and regular viewing mode
-(void) fullImageViewController: (FullImageViewController *)controller
              amendedStereogram: (Stereogram *)newStereogram
                    atIndexPath: (NSIndexPath *)indexPath;

@end

#pragma mark -

@interface FullImageViewController : UIViewController <UIScrollViewDelegate>
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;

    /// Delegate with callbacks if the user approved, rejected or modified the image.
@property (nonatomic, copy) id<FullImageViewControllerDelegate> delegate;

    /// Initialise the image view to display the given image.
    /// If forApproval is YES, the view gets a 'Keep' button, and if pressed, calls approvalBlock, which should copy the image to permanent storage.
-(instancetype) initWithStereogram: (Stereogram *)stereogram
                       forApproval: (BOOL)forApproval
                          delegate: (id<FullImageViewControllerDelegate>)delegate;

    /// Convenience initialiser. Open in normal mode, viewing the index at the selected index path.
-(instancetype) initWithStereogram: (Stereogram *)stereogram
                       atIndexPath: (NSIndexPath *)indexPath
                          delegate: (id<FullImageViewControllerDelegate>)delegate;


@end
