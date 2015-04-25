//
//  PWPhotoViewController.h
//  Stereogram
//
//  Created by Patrick Wallace on 20/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

@import UIKit;
@import MessageUI;
#import "FullImageViewController.h"
#import "StereogramViewController.h"
@class PhotoStore;

/*
 * View controller presenting a view which shows a collection of thumbnail images and allows the user to select or deselect them.
 * It also allows the user to initiate the photo-taking process and is generally the main view in the application.
 */
@interface PhotoViewController : UIViewController <UINavigationControllerDelegate, UICollectionViewDelegate, FullImageViewControllerDelegate, StereogramViewControllerDelegate, MFMailComposeViewControllerDelegate> {
}

/*!
 * Designated Initializer. Initialize the object and set the default value for photoStore.
 *
 * @param photoStore The photo store from which to take image thumbnails. Also update operations will be applied to the images in this store.
 */
-(instancetype)initWithPhotoStore: (PhotoStore*)photoStore NS_DESIGNATED_INITIALIZER;

/*! Convenience Initializer. Initialize the object setting photoStore to nil. */
-(instancetype)init;

/*!
 * This is the photoStore that houses the image we will display.
 * Any user actions taken on the displayed image will be updated in the photo store.
 */
@property (nonatomic, strong) PhotoStore *photoStore;

@end
