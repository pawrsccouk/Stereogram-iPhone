//
//  PWPhotoViewController.h
//  Stereogram
//
//  Created by Patrick Wallace on 20/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

@import UIKit;
#import "FullImageViewController.h"
#import "StereogramViewController.h"
@class PhotoStore;

@interface PhotoViewController : UIViewController <UINavigationControllerDelegate, UICollectionViewDelegate, FullImageViewControllerDelegate, StereogramViewControllerDelegate> {
}
@property (nonatomic, weak) IBOutlet UICollectionView *photoCollectionView;

    /// Designated Initializer. Initialize the object and set the default value for photoStore.
-(instancetype)initWithPhotoStore: (PhotoStore*)photoStore NS_DESIGNATED_INITIALIZER;

    /// Convenience Initializer. Initialize the object setting photoStore to nil.
-(instancetype)init;

    /// This is the photoStore that houses the image we will display.  Any user actions taken on the displayed image will be updated in the photo store.
@property (nonatomic, strong) PhotoStore *photoStore;

@end
