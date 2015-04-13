//
//  PWPhotoViewController.h
//  Stereogram
//
//  Created by Patrick Wallace on 20/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PWPhotoStore;

@interface PWPhotoViewController : UIViewController <UIImagePickerControllerDelegate,
                                                     UINavigationControllerDelegate,
                                                     UICollectionViewDelegate>
{
    IBOutlet UICollectionView __weak *photoCollection;
}

-(instancetype) initWithPhotoStore: (PWPhotoStore*)photoStore NS_DESIGNATED_INITIALIZER;

@end
