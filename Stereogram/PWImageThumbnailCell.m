//
//  PWImageThumbnailCell.m
//  Stereogram
//
//  Created by Patrick Wallace on 22/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import "PWImageThumbnailCell.h"


@implementation PWImageThumbnailCell
@synthesize image = _image;


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
            // Initialization code - Create and add the image thumbnail view
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:self.contentView.frame];
        [self.contentView addSubview:imgView];
        imageView = imgView;
            // Now add the overlay view which will show when the object is selected.
        CGSize selImageSize = self.selectedImageSize;
        CGPoint selImageOrigin = CGPointMake(frame.size.width - selImageSize.width, frame.size.height - selImageSize.height);
        CGRect selectOverlayFrame = { .origin = selImageOrigin, .size = selImageSize };
        imgView = [[UIImageView alloc] initWithFrame:selectOverlayFrame];
        imgView.image = [self.class unselectedImage];
        [self.contentView addSubview:imgView];
        selectionOverlayView = imgView;
    }
    return self;
}

-(void)setImage:(UIImage *)image
{
    if(_image != image) {
        NSAssert(imageView, @"imageView should not be nil");
        imageView.image = image;
        _image = image;
    }
}

-(CGSize)selectedImageSize { return CGSizeMake(46, 46); }

-(NSString *)description
{
    return [NSString stringWithFormat:@"%@ imageView=%@", [super description], imageView];
}

-(void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    selectionOverlayView.image = selected ? [self.class selectedImage] : [self.class unselectedImage];
}

+(UIImage *)selectedImage
{
    static UIImage *selectedImage;
    if(! selectedImage)
        selectedImage = [UIImage imageNamed:@"Tick"];
    return selectedImage;
}

+(UIImage *)unselectedImage
{
    static UIImage *notSelectedImage;
    if(! notSelectedImage)
        notSelectedImage = [UIImage imageNamed:@"Unselected Overlay"];
    return notSelectedImage;
}

@end
