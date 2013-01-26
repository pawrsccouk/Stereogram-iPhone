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
    imageView.image = image;
    [imageView sizeToFit];
    scrollView.contentSize = imageView.bounds.size;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
@end
