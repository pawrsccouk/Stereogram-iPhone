//
//  PWPhotoViewController.h
//  Stereogram
//
//  Created by Patrick Wallace on 20/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PWPhotoViewController : UIViewController <UIImagePickerControllerDelegate,
                                                     UINavigationControllerDelegate,
                                                     UICollectionViewDataSource,
                                                     UICollectionViewDelegate>
{
    IBOutlet UICollectionView __weak *photoCollection;
}


@end
