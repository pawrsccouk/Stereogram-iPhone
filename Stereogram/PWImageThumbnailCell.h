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
}

@property (nonatomic, weak) UIImage *image;

@end
