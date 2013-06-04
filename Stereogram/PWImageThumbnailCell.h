//
//  PWImageThumbnailCell.h
//  Stereogram
//
//  Created by Patrick Wallace on 22/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PWImageThumbnailCell : UICollectionViewCell

    // Image which will be displayed in the image view.
@property (nonatomic, strong) UIImage *image;

    // Size of the selected overlay image.
@property (nonatomic, readonly) CGSize selectedImageSize;

    // Images which are overlaid on the thumbnail to indicate if it is selected or not.
+(UIImage*)unselectedImage;
+(UIImage*)selectedImage;

@end
