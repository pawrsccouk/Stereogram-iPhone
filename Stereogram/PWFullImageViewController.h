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
    UIImage *image;
}

    // Block which will be called if the user approved the image.
@property (nonatomic, copy) void (^approvalBlock)(void);

-(id)initWithImage:(UIImage*)image forApproval:(BOOL)approval;

@end
