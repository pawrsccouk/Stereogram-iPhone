//
//  PWFullImageViewController.h
//  Stereogram
//
//  Created by Patrick Wallace on 23/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PWFullImageViewController : UIViewController <UIScrollViewDelegate>
{
    IBOutlet UIImageView  *imageView;
    IBOutlet UIScrollView  *scrollView;
}

    // Block which will be called if the user approved the image.
@property (nonatomic, copy) void (^approvalBlock)(void);

    // Initialise the image view to display the given image.
    // If forApproval is YES, the view gets a 'Keep' button, and if pressed, calls approvalBlock
    // which should copy the image to permanent storage.
-(id)initWithImage:(UIImage*)image forApproval:(BOOL)forApproval;

@end
