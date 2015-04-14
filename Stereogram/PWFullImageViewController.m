//
//  PWFullImageViewController.m
//  Stereogram
//
//  Created by Patrick Wallace on 23/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import "PWFullImageViewController.h"
#import "ImageManager.h"
#import "NSError_AlertSupport.h"

@interface PWFullImageViewController () {
    UIImage *_image;
    UIActivityIndicatorView *_activityIndicator;
    NSIndexPath *_indexPath;
}

    /// Designated Initializer.
-(instancetype) initWithImage: (UIImage *)image
                  atIndexPath: (NSIndexPath *)indexPath
                  forApproval: (BOOL)forApproval
                     delegate: (id<PWFullImageViewControllerDelegate>)delegate NS_DESIGNATED_INITIALIZER;

@end

@implementation PWFullImageViewController
@synthesize delegate = _delegate, imageView = _imageView, scrollView = _scrollView;

-(instancetype) initWithImage: (UIImage *)image
                  atIndexPath: (NSIndexPath *)indexPath
                     delegate: (id<PWFullImageViewControllerDelegate>)delegate {
    return [self initWithImage:image
                   atIndexPath:indexPath
                   forApproval:NO
                      delegate:delegate];
}

- (instancetype)initWithImage:(UIImage *)image
                  forApproval:(BOOL)forApproval
                     delegate:(id<PWFullImageViewControllerDelegate>)delegate {
    return [self initWithImage:image
                   atIndexPath:nil
                   forApproval:forApproval
                      delegate:delegate];
}

-(id)initWithImage: (UIImage *)image
       atIndexPath: (NSIndexPath *)indexPath
       forApproval: (BOOL)approval
          delegate: (id<PWFullImageViewControllerDelegate>)delegate {
    self = [super initWithNibName:@"PWFullImageView" bundle:nil];
    if (self) {
        _image = image;
        _delegate = delegate;
        _indexPath = indexPath;
        UIBarButtonItem *toggleViewMethodButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Toggle View Method"
                                                                                       style:UIBarButtonItemStyleBordered
                                                                                      target:self
                                                                                      action:@selector(changeViewingMethod:)];
            // If we are using this to approve an image, then display "Keep" and "Discard" buttons as well as the change viewing method button.
        if (approval) {
            UIBarButtonItem *keepButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Keep"
                                                                               style:UIBarButtonItemStyleBordered
                                                                              target:self
                                                                              action:@selector(keepPhoto)];
            UIBarButtonItem *discardButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Discard"
                                                                                  style:UIBarButtonItemStyleBordered
                                                                                 target:self
                                                                                 action:@selector(discardPhoto)];
            self.navigationItem.rightBarButtonItems = @[keepButtonItem, discardButtonItem];
            self.navigationItem.leftBarButtonItem = toggleViewMethodButtonItem;
        } else {
            self.navigationItem.rightBarButtonItem = toggleViewMethodButtonItem;
        }
    }
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
        // Calculate the size of the underlying image, and then use that to set the scrollview's bounds.
    self.imageView.image = _image;
    [self.imageView sizeToFit];
}

-(void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
        // Called on a resize or autorotate. This will change the scrollview's scaling factors so recalculate them.
    [self setupScrollviewAnimated:YES];
}

-(void) keepPhoto {
    id<PWFullImageViewControllerDelegate> delegate = self.delegate;
    NSAssert(delegate, @"No delegate assigned to view controller %@", self);
    if ([delegate respondsToSelector:@selector(fullImageViewController:approvedImage:)]) {
        [delegate fullImageViewController:self
                            approvedImage:_image];
    }
    [delegate dismissedFullImageViewController:self];
}

-(void) discardPhoto {
    [self.presentingViewController dismissViewControllerAnimated:YES
                                                      completion:nil];
}


-(BOOL) showActivityIndicator {
    return !_activityIndicator.hidden;
}

-(void) setShowActivityIndicator: (BOOL)hidden {
    _activityIndicator.hidden = !hidden;
    if (hidden) {
        [_activityIndicator startAnimating];
    } else {
        [_activityIndicator stopAnimating];
    }
}

-(void) setupActivityIndicator {
        // Add the activity indicator to the view if it is not there already. It starts off hidden.
    if (![_activityIndicator isDescendantOfView:self.view]) {
        [self.view addSubview:_activityIndicator];
    }
    
        // Ensure the activity indicator fits in the frame.
    CGSize activitySize = _activityIndicator.bounds.size;
    CGSize parentSize = self.view.bounds.size;
    CGRect frame = CGRectMake((parentSize.width / 2) - (activitySize.width / 2), (parentSize.height / 2) - (activitySize.height / 2), activitySize.width, activitySize.height);
    _activityIndicator.frame = frame;
}

-(IBAction) changeViewingMethod: (id)sender {
    UIImage *oldImage = _image;
    self.showActivityIndicator = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *newImage = [ImageManager changeViewingMethod:oldImage];
        if (newImage) {
            dispatch_async(dispatch_get_main_queue(), ^{
                    // Clear the activity indicator and update the image in this view.
                self.showActivityIndicator = NO;
                _image = newImage;
                self.imageView.image = newImage;
                [self.imageView sizeToFit];
                    // Notify the system that the image has been changed in the view.
                if ([self.delegate respondsToSelector:@selector(fullImageViewController:amendedImage:atIndexPath:)]) {
                    [self.delegate fullImageViewController:self
                                              amendedImage:newImage
                                               atIndexPath:_indexPath];
                }
            });
        } else { // newImage is nil.
            dispatch_async(dispatch_get_main_queue(), ^{
                self.showActivityIndicator = false;
                NSError *error = [NSError errorWithDomain:@"Error creating new image." code:0 userInfo:nil];
                [error showAlertWithTitle:@"Error changing viewing method" parentViewController:self];
            });
        }
    });
}

-(void) logData {
    CGRect frame = self.view.frame;
    NSLog(@"Scroll view frame = (%f,%f),(%f,%f)", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height );
    frame = self.imageView.frame;
    NSLog(@"Image view frame = (%f,%f),(%f,%f)", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height );
    NSLog(@"ImageView = %@, Image = %@ Image size = (%f,%f)", self.imageView, self.self.imageView.image, self.imageView.image.size.width, self.imageView.image.size.height);
    NSLog(@"ScrollView = %@, contentSize = (%f, %f)\n\n", self.scrollView, self.scrollView.contentSize.width, self.scrollView.contentSize.height);
}


#pragma mark - Scrollview delegate

-(UIView *) viewForZoomingInScrollView: (UIScrollView *)scrollView {
    return self.imageView;
}


#pragma mark - Private methods

-(void) setupScrollviewAnimated: (BOOL)animated {
    self.scrollView.contentSize = self.imageView.bounds.size;
        // Set the zoom info so the image fits in the window by default, but can be zoomed in. Respect the aspect ratio.
    CGSize imageSize = self.imageView.image.size, viewSize = self.scrollView.bounds.size;
    self.scrollView.maximumZoomScale = 1.0;  // Cannot zoom in past the 1:1 ratio.
    self.scrollView.minimumZoomScale = MIN(viewSize.width / imageSize.width, viewSize.height / imageSize.height);
        // Default to showing the whole image.
    [self.scrollView setZoomScale:self.scrollView.minimumZoomScale
                         animated:animated];
}




@end
