//
//  PWImageThumbnailCell.m
//  Stereogram
//
//  Created by Patrick Wallace on 22/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import "ImageThumbnailCell.h"

@interface ImageThumbnailCell () {
    UIImageView __weak *_imageView;
    UIImageView __weak *_selectionOverlayView;
}
@end


@implementation ImageThumbnailCell
@synthesize image = _image;


-(id) initWithFrame: (CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
            // Initialization code - Create and add the image thumbnail view
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.contentView.frame];
        [self.contentView addSubview:imageView];
        _imageView = imageView;
        
            // Now add the overlay view which will show when the object is selected.
        CGSize selImageSize = self.selectedImageSize;
        CGPoint selImageOrigin = CGPointMake(frame.size.width - selImageSize.width, frame.size.height - selImageSize.height);
        CGRect selectOverlayFrame = { .origin = selImageOrigin, .size = selImageSize };
        imageView = [[UIImageView alloc] initWithFrame:selectOverlayFrame];
        imageView.image = [self.class unselectedImage];
        [self.contentView addSubview:imageView];
        _selectionOverlayView = imageView;
    }
    return self;
}

-(void) setImage: (UIImage *)image {
    if(_image != image) {
        NSAssert(_imageView, @"_imageView should not be nil");
        _imageView.image = image;
        _image = image;
    }
}

-(CGSize) selectedImageSize { return CGSizeMake(46, 46); }

-(NSString *) description {
    return [NSString stringWithFormat:@"%@ _imageView=%@", [super description], _imageView];
}

-(void) setSelected: (BOOL)selected {
    [super setSelected:selected];
    _selectionOverlayView.image = selected ? [self.class selectedImage] : [self.class unselectedImage];
}

+(UIImage *) selectedImage {
    static UIImage *selectedImage;
    if(! selectedImage) {
        selectedImage = [UIImage imageNamed:@"Tick Overlay"];
        NSAssert(selectedImage, @"Image called Tick Overlay was not in the bundle.");
    }
    return selectedImage;
}

+(UIImage *) unselectedImage {
    static UIImage *notSelectedImage;
    if(! notSelectedImage) {
        notSelectedImage = [UIImage imageNamed:@"Unticked Overlay"];
        NSAssert(notSelectedImage, @"Image called Unticked Overlay was not found in the bundle.");
    }
    return notSelectedImage;
}

@end
