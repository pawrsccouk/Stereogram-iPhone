//
//  PWImageThumbnailCell.h
//  Stereogram
//
//  Created by Patrick Wallace on 22/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 * Collection view cell displaying a single thumbnail image with an optional tick icon overlay.
 */
@interface ImageThumbnailCell : UICollectionViewCell

/*!
 * Image which will be displayed in the image view.
 */
@property (nonatomic, strong) UIImage *image;

/*!
 * Size of the selected overlay image.
 */
@property (nonatomic, readonly) CGSize selectedImageSize;

@end
