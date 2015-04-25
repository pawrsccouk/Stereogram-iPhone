//
//  WelcomeViewController.h
//  Stereogram
//
//  Created by Patrick Wallace on 13/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

@import UIKit;
#import "FullImageViewController.h"
#import "StereogramViewController.h"
@class PhotoStore;

/*!
 * View controller presenting a temporary view with introductory welcome text for the user.
 *
 * This will only be displayed when there are no photos in the view controller. It obscures the Photo View and also holds the Photo icon.
 * The user can take a new photo and then this view will remove itself from the hierarchy revealing the standard photo view beneath.
 */
@interface WelcomeViewController : UIViewController  <FullImageViewControllerDelegate, StereogramViewControllerDelegate>

/*!
 * Designated Initializer.  
 *
 * @param photoStore The photo store which will accept the new image if the user decides to take one.
 */
-(instancetype)initWithPhotoStore: (PhotoStore *)photoStore NS_DESIGNATED_INITIALIZER;


@end
