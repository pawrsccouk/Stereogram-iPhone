//
//  PWFullImageViewController.m
//  Stereogram
//
//  Created by Patrick Wallace on 23/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import "FullImageViewController.h"
#import "ImageManager.h"
#import "NSError_AlertSupport.h"
#import "Stereogram.h"
#import "PWAlertView.h"
#import "PWActionSheet.h"

@interface FullImageViewController () {
    Stereogram *_stereogram;
    UIActivityIndicatorView *_activityIndicator;
    NSIndexPath *_indexPath;
    UIBarButtonItem __weak *_selectViewModeButtonItem;
    PWAlertView *_alertView;
}

    /// Designated Initializer.
-(instancetype) initWithStereogram: (Stereogram *)stereogram
                       atIndexPath: (NSIndexPath *)indexPath
                       forApproval: (BOOL)forApproval
                          delegate: (id<FullImageViewControllerDelegate>)delegate NS_DESIGNATED_INITIALIZER;

@end

@implementation FullImageViewController
@synthesize delegate = _delegate, imageView = _imageView, scrollView = _scrollView;

#pragma mark Constructors

-(instancetype) initWithStereogram: (Stereogram *)stereogram
                       atIndexPath: (NSIndexPath *)indexPath
                          delegate: (id<FullImageViewControllerDelegate>)delegate {
    return [self initWithStereogram:stereogram
                        atIndexPath:indexPath
                        forApproval:NO
                           delegate:delegate];
}

-(instancetype) initWithStereogram: (Stereogram *)stereogram
                       forApproval: (BOOL)forApproval
                          delegate: (id<FullImageViewControllerDelegate>)delegate {
    return [self initWithStereogram:stereogram
                        atIndexPath:nil
                        forApproval:forApproval
                           delegate:delegate];
}

-(instancetype) initWithStereogram: (Stereogram *)image
                       atIndexPath: (NSIndexPath *)indexPath
                       forApproval: (BOOL)approval
                          delegate: (id<FullImageViewControllerDelegate>)delegate {
    self = [super initWithNibName:@"FullImageView" bundle:nil];
    if (self) {
        _stereogram = image;
        _delegate = delegate;
        _indexPath = indexPath;
        UIBarButtonItem *selectViewMethodButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Change View Method"
                                                                                       style:UIBarButtonItemStyleBordered
                                                                                      target:self
                                                                                      action:@selector(selectViewingMethod:)];
        _selectViewModeButtonItem = selectViewMethodButtonItem;
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
            self.navigationItem.leftBarButtonItem = selectViewMethodButtonItem;
        } else {
            self.navigationItem.rightBarButtonItem = selectViewMethodButtonItem;
        }
    }
    return self;
}

#pragma mark Overrides

- (void) viewDidLoad {
    [super viewDidLoad];
        // Calculate the size of the underlying image, and then use that to set the scrollview's bounds.
    NSError *error = nil;
    UIImage *fullImage = [_stereogram stereogramImage:&error];
    if (!fullImage) {
        NSLog(@"viewDidLoad: Failed to load image from stereogram %@", _stereogram);
    }
    self.imageView.image = fullImage;
    [self.imageView sizeToFit];
}

-(void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
        // Called on a resize or autorotate. This will change the scrollview's scaling factors so recalculate them.
    [self setupScrollviewAnimated:YES];
}

#pragma mark Callbacks

    /// Prompt the user with a menu of possible viewing methods they can select.

-(void) selectViewingMethod: (id)sender {
    
        // TODO: Make a menu
    _alertView = [PWAlertView alertViewWithTitle: @"Select viewing style"
                                                                             message: @"Choose one of the styles below"
                                                                      preferredStyle: UIAlertControllerStyleActionSheet ];
    
    PWAction *animationAction = [PWAction actionWithTitle: @"Animation"
                                                              style: UIAlertActionStyleDefault
                                                            handler: ^(PWAction *action) {
                                                                [self changeViewingMethod:ViewingMethod_AnimatedGIF];
                                                            }];
    [_alertView addAction:animationAction];
    
    PWAction *crossEyedAction = [PWAction actionWithTitle: @"Cross-eyed"
                                                              style: UIAlertActionStyleDefault
                                                            handler: ^(PWAction *action) {
        [self changeViewingMethod:ViewingMethod_CrossEye];
    }];
    [_alertView addAction:crossEyedAction];
    
    PWAction *wallEyedAction = [PWAction actionWithTitle: @"Wall-eyed"
                                                             style: UIAlertActionStyleDefault
                                                           handler: ^(PWAction *action) {
        [self changeViewingMethod:ViewingMethod_WallEye];
    }];
    [_alertView addAction:wallEyedAction];
    
    _alertView.popoverPresentationItem = _selectViewModeButtonItem;
    [_alertView show];
}


-(void) changeViewingMethod: (ViewingMethod)viewingMethod {
    
    self.showActivityIndicator = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        _stereogram.viewingMethod = viewingMethod;
        
             // Reload the image while we are in the background thread.
        NSError *error = nil;
        if ([_stereogram refresh:&error]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                    // Clear the activity indicator and update the image in this view.
                self.showActivityIndicator = NO;
                UIImage *fullImage = [_stereogram stereogramImage:nil];
                NSAssert(fullImage, @"Stereogram %@ image was not properly cached.", _stereogram);
                self.imageView.image = fullImage;
                [self setupScrollviewAnimated:YES];
                    // Notify the system that the image has been changed in the view.
                if ([self.delegate respondsToSelector:@selector(fullImageViewController:amendedStereogram:atIndexPath:)]) {
                    [self.delegate fullImageViewController:self
                                         amendedStereogram:_stereogram
                                               atIndexPath:_indexPath];
                }
                
            });
        } else { // stereogram reset failed.
            dispatch_async(dispatch_get_main_queue(), ^{
                
                self.showActivityIndicator = false;
                [error showAlertWithTitle:@"Error changing viewing method"
                     parentViewController:self];
                
            });
        }
    });
}

-(void) keepPhoto {
    id<FullImageViewControllerDelegate> delegate = self.delegate;
    NSAssert(delegate, @"No delegate assigned to view controller %@", self);
    if ([delegate respondsToSelector:@selector(fullImageViewController:approvingStereogram:result:)]) {
        [delegate fullImageViewController:self
                      approvingStereogram:_stereogram
                                   result:ApprovalResult_Approved];
    }
    [delegate dismissedFullImageViewController:self];
}

-(void) discardPhoto {
    id<FullImageViewControllerDelegate> delegate = self.delegate;
    NSAssert(delegate, @"No delegate assigned to view controller %@", self);
    if ([delegate respondsToSelector:@selector(fullImageViewController:approvingStereogram:result:)]) {
        [delegate fullImageViewController:self
                      approvingStereogram:_stereogram
                                   result:ApprovalResult_Discarded];
    }
    [delegate dismissedFullImageViewController:self];
}

#pragma mark Activity Indicator
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
