//
//  PWFullImageViewController.h
//  Stereogram
//
//  Created by Patrick Wallace on 23/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import <UIKit/UIKit.h>
@class FullImageViewController;

@protocol FullImageViewControllerDelegate <NSObject>
    
         // Called when the user has requested the controller be closed. On receipt of this message, the delegagte must remove the view controller from the stack.
-(void) dismissedFullImageViewController: (FullImageViewController *)controller;

@optional

       // Called if the controller is in Approval mode and the user has approved an image.
-(void) fullImageViewController: (FullImageViewController *)controller
                  approvedImage: (UIImage *)image;
    
        // Called if the controller is viewing an image, and the image changed.
        // This will be called in both approval mode and regular viewing mode
-(void) fullImageViewController: (FullImageViewController *)controller
                   amendedImage: (UIImage *)newImage
                    atIndexPath: (NSIndexPath *)indexPath;

@end

#pragma mark -

@interface FullImageViewController : UIViewController <UIScrollViewDelegate>
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;

    /// Block which will be called if the user approved the image.
@property (nonatomic, copy) id<FullImageViewControllerDelegate> delegate;

    /// Initialise the image view to display the given image.
    /// If forApproval is YES, the view gets a 'Keep' button, and if pressed, calls approvalBlock, which should copy the image to permanent storage.
-(instancetype) initWithImage: (UIImage*)image
                  forApproval: (BOOL)forApproval
                     delegate: (id<FullImageViewControllerDelegate>)delegate;

    /// Convenience initialiser. Open in normal mode, viewing the index at the selected index path.
-(instancetype) initWithImage: (UIImage*)image
                  atIndexPath: (NSIndexPath *)indexPath
                     delegate: (id<FullImageViewControllerDelegate>)delegate;


@end
