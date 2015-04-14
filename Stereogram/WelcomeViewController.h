//
//  WelcomeViewController.h
//  Stereogram
//
//  Created by Patrick Wallace on 13/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FullImageViewController.h"
#import "StereogramViewController.h"
@class PhotoStore;

@interface WelcomeViewController : UIViewController  <FullImageViewControllerDelegate, StereogramViewControllerDelegate>

@property (nonatomic, strong) PhotoStore *photoStore;

@end
