//
//  PWImageThumbnailCell.h
//  Stereogram
//
//  Created by Patrick Wallace on 22/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PWImageThumbnailCell : UICollectionViewCell
{
    UIImageView __weak *imageView;
    UIImageView __weak *selectionOverlayView;
}

@property (nonatomic, weak) UIImage *image;

    // Images which are overlaid on the thumbnail to indicate if it is selected or not.
+(UIImage*)unselectedImage;
+(UIImage*)selectedImage;

@end
