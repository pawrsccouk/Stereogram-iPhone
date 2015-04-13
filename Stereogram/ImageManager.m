//
//  ImageManager.m
//  Stereogram
//
//  Created by Patrick Wallace on 10/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

#import "ImageManager.h"
#import "ErrorData.h"

@implementation ImageManager

+(UIImage*) imageFromFile: (NSString*)filePath
                    error: (NSError**)errorPtr {
    NSAssert(filePath && [[NSFileManager defaultManager] fileExistsAtPath:filePath], @"filePath [%@] does not point to a file.", filePath);
    return [UIImage imageWithData:[NSData dataWithContentsOfFile:filePath options:0 error:errorPtr]];
}

+(UIImage *) makeStereogramWithLeftPhoto: (UIImage *)leftPhoto
                              rightPhoto: (UIImage *)rightPhoto {
    NSAssert(leftPhoto.scale == rightPhoto.scale, @"Image scales %f and %f need to be the same.", leftPhoto.scale, rightPhoto.scale);
    CGSize stereogramSize = CGSizeMake(leftPhoto.size.width + rightPhoto.size.width, MAX(leftPhoto.size.height, rightPhoto.size.height));
    UIImage *stereogram = nil;
    UIGraphicsBeginImageContextWithOptions(stereogramSize, NO, leftPhoto.scale);
    @try {
        [leftPhoto drawAtPoint:CGPointMake(0, 0)];
        [rightPhoto drawAtPoint:CGPointMake(leftPhoto.size.width, 0)];
        stereogram = UIGraphicsGetImageFromCurrentImageContext();
    }
    @finally {
        UIGraphicsEndImageContext();
    }
    NSAssert(stereogram, @"Stereogram not created.");
    return stereogram;
}

+(UIImage *) changeViewingMethod: (UIImage *)sourceImage {
    if (sourceImage) {
        UIImage *swappedImage = [self makeStereogramWithLeftPhoto:[self getHalfOfImage:sourceImage whichHalf:RightHalf]
                                                       rightPhoto:[self getHalfOfImage:sourceImage whichHalf:LeftHalf]];
        NSAssert(CGSizeEqualToSize(swappedImage.size, sourceImage.size), @"Error swapping the image. Size (%f,%f) doesn't match original (%f, %f)",
                 swappedImage.size.width, swappedImage.size.height, sourceImage.size.width, sourceImage.size.height);
        return swappedImage;
    }
    return nil;
}


//static NSError *makeUnknownError() {
//    return [NSError errorWithDomain:kPWErrorDomainPhotoStore
//                               code:kPWErrorCodesUnknownError
//                           userInfo:@{ (NSString*)kCFErrorDescriptionKey : @"Unknown error" }];
//}
//
//static NSError *makeOutOfBoundsError(NSInteger index) {
//    NSString *errorText = [NSString stringWithFormat:@"Index %ld is out of bounds", (long)index];
//    return [NSError errorWithDomain:kPWErrorDomainPhotoStore
//                               code:kPWErrorCodesIndexOutOfBounds
//                           userInfo:@{ (NSString*)kCFErrorDescriptionKey : errorText }];
//}
//

+(UIImage *) getHalfOfImage: (UIImage *)image
                  whichHalf: (WhichHalf)whichHalf {
    CGRect rectToKeep = (whichHalf == LeftHalf) ? CGRectMake(0, 0, image.size.width / 2.0, image.size.height)
    : CGRectMake(image.size.width / 2.0, 0, image.size.width / 2.0, image.size.height );
    
    CGImageRef imgPartRef = CGImageCreateWithImageInRect(image.CGImage, rectToKeep);
    UIImage *imgPart = [UIImage imageWithCGImage:imgPartRef];
    CGImageRelease(imgPartRef);
    return imgPart;
};

@end
