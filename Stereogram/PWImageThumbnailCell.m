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
        // Initialization code
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:self.contentView.frame];
        [self.contentView addSubview:imgView];
        imageView = imgView;
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

-(NSString *)description
{
    return [NSString stringWithFormat:@"%@ imageView=%@", [super description], imageView];
}
@end
