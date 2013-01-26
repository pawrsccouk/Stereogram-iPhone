//
//  PWFullImageViewController.m
//  Stereogram
//
//  Created by Patrick Wallace on 23/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import "PWFullImageViewController.h"

@interface PWFullImageViewController ()

@end

@implementation PWFullImageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:@"PWFullImageView" bundle:nibBundleOrNil];
}

-(id)initWithImage:(UIImage *)img
{
    self = [self init];
    if(self) {
//        UIBarButtonItem *testButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks
//        target:self
//        action:@selector(logData)];
//        self.navigationItem.rightBarButtonItem = testButton;
        
        image = img;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
        // Calculate the size of the underlying image, and then use that to set the scrollview's bounds.
    imageView.image = image;
    [imageView sizeToFit];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
        // Called on a resize or autorotate. This will change the scrollview's scaling factors so recalculate them.
    [self setupScrollviewAnimated:YES];
}

-(void)logData
{
    CGRect frame = self.view.frame;
    NSLog(@"Scroll view frame = (%f,%f),(%f,%f)", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height );
    frame = imageView.frame;
    NSLog(@"Image view frame = (%f,%f),(%f,%f)", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height );
    NSLog(@"ImageView = %@, Image = %@ Image size = (%f,%f)", imageView, imageView.image, imageView.image.size.width, imageView.image.size.height);
    NSLog(@"ScrollView = %@, contentSize = (%f, %f)\n\n", scrollView, scrollView.contentSize.width, scrollView.contentSize.height);
}


#pragma mark - Scrollview delegate

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return imageView;
}


#pragma mark - Private methods

-(void)setupScrollviewAnimated:(BOOL) animated
{
    scrollView.contentSize = imageView.bounds.size;
    
        // Set the zoom info so the image fits in the window by default, but can be zoomed in. Respect the aspect ratio.
    CGSize imageSize = imageView.image.size, viewSize = scrollView.bounds.size;
    scrollView.maximumZoomScale = 1.0;  // Cannot zoom in past the 1:1 ratio.
    scrollView.minimumZoomScale = MIN(viewSize.width / imageSize.width, viewSize.height / imageSize.height);
        // Default to showing the whole image.
    [scrollView setZoomScale:scrollView.minimumZoomScale animated:animated];
}




@end
