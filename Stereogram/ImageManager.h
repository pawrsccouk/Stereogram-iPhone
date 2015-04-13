//
//  ImageManager.h
//  Stereogram
//
//  Created by Patrick Wallace on 10/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageManager : NSObject

    /// Given a path to an image, try and load it, returning the image on success and nil + *errorPtr on error.
+(UIImage*) imageFromFile: (NSString*)filePath
                    error: (NSError**)errorPtr;

    /// Copies leftPhoto and rightPhoto to make a single image.
+(UIImage *) makeStereogramWithLeftPhoto: (UIImage *)leftPhoto
                              rightPhoto: (UIImage *)rightPhoto;

    /// Toggles the viewing method from crosseye to walleye and back for the image at position <index>.
+(UIImage *) changeViewingMethod: (UIImage *)sourceImage;

    /// In halfImage, this specifies which half to return.
typedef NS_ENUM(NSUInteger, WhichHalf) { RightHalf, LeftHalf };

+(UIImage *) getHalfOfImage: (UIImage *) image
                  whichHalf: (WhichHalf) whichHalf;

@end
