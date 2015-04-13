//
//  WelcomeViewController.h
//  Stereogram
//
//  Created by Patrick Wallace on 13/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PWFullImageViewController.h"
#import "StereogramViewController.h"
@class PWPhotoStore;

@interface WelcomeViewController : UIViewController  <PWFullImageViewControllerDelegate, StereogramViewControllerDelegate>

@property (nonatomic, strong) PWPhotoStore *photoStore;

@end
