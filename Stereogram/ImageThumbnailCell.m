//
//  PWImageThumbnailCell.m
//  Stereogram
//
//  Created by Patrick Wallace on 22/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import "ImageThumbnailCell.h"

@interface ImageThumbnailCell () {
    /*! The view containing the image thumbnail i.e. the cell content. */
    UIImageView __weak *_imageView;
    
    /*! A view containing a tick image which will be overlaid above selected cell images. */
    UIImageView __weak *_selectionOverlayView;
}

/*!
 * Class Method. Cache the selection tick image the first time it is needed and return it.
 *
 * @returns The image to display if the cell is selected.
 */
+(UIImage *)selectedImage;
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
        
            // Now add the overlay view which will show a tick when the object is selected.
        CGSize selImageSize = self.selectedImageSize;
        CGPoint selImageOrigin = CGPointMake(frame.size.width - selImageSize.width, frame.size.height - selImageSize.height);
        CGRect selectOverlayFrame = { .origin = selImageOrigin, .size = selImageSize };
        UIImageView *tickView = [[UIImageView alloc] initWithFrame:selectOverlayFrame];
        tickView.image = nil;
        [self.contentView addSubview:tickView];
        _selectionOverlayView = tickView;
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
    _selectionOverlayView.image = selected ? [self.class selectedImage] : nil;
}

+(UIImage *) selectedImage {
    static UIImage *_selectedImage;
    if(! _selectedImage) {
        _selectedImage = [UIImage imageNamed:@"Tick Overlay"];
        NSAssert(_selectedImage, @"Image called Tick Overlay was not in the bundle.");
    }
    return _selectedImage;
}

@end
