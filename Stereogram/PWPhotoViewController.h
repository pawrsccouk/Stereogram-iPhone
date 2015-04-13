//
//  PWPhotoViewController.h
//  Stereogram
//
//  Created by Patrick Wallace on 20/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PWFullImageViewController.h"
@class PWPhotoStore;

@interface PWPhotoViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegate, PWFullImageViewControllerDelegate> {
    IBOutlet UICollectionView __weak *photoCollectionView;
}

    /// Designated Initializer. Initialize the object and set the default value for photoStore.
-(instancetype)initWithPhotoStore: (PWPhotoStore*)photoStore NS_DESIGNATED_INITIALIZER;

    /// Convenience Initializer. Initialize the object setting photoStore to nil.
-(instancetype)init;

    /// This is the photoStore that houses the image we will display.  Any user actions taken on the displayed image will be updated in the photo store.
@property (nonatomic, strong) PWPhotoStore *photoStore;

@end
