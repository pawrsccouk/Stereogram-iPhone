/*!
@header ImageManager
@abstract A collection of functions for handling images.
@author Patrick Wallace
@copyright (c) 2015 Patrick Wallace. All rights reserved.
*/

@import UIKit;
NS_ASSUME_NONNULL_BEGIN

/*! Collection of class functions for handling images.
 * @todo Remove ImageManager.
 */
@interface ImageManager : NSObject

/*! Load an image from disk
 * @param filePath Path to an image file on disk.
 * @param errorPtr Pointer to return error data if necessary.
 * @return The image if loaded correctly, nil if it didn't.
 */
+(nullable UIImage*) imageFromFile: (NSString*)filePath
                             error: (NSError* __nullable *)errorPtr;

/*! Returns a stereogram using two images.
 * @param leftPhoto The left-hand image.
 * @param rightPhoto The right-hand image.
 * @return The new image. Should never be null.
 */
+(UIImage *) makeStereogramWithLeftPhoto: (UIImage *)leftPhoto
                              rightPhoto: (UIImage *)rightPhoto;

/*! Toggles the viewing method from crosseye to walleye and back
 * @param sourceImage The image to update.
 * @return A copy of sourceImage with the left and right halves swapped.
 *
 * @note This works by splitting the source image in two and swapping the left and right halves.  This probably won't work in future.
 *
 * @todo Remove this method.
 */
+(UIImage *) changeViewingMethod: (UIImage *)sourceImage;

/*! @enum
 * In halfImage, this specifies which half to return. 
 * @constant LeftHalf The leftmost half of the image.
 * @constant RightHalf The rightmost half of the image.
 */
typedef enum WhichHalf {
    RightHalf,
    LeftHalf
} WhichHalf;

/*! Returns a copy of the left or right half of an image.
 * @param image The image to copy.
 * @param whichHalf LeftHalf or RightHalf, which half to copy.
 * @return A copy of half of the image. Should never be null.
 */
+(UIImage *) getHalfOfImage: (UIImage *) image
                  whichHalf: (WhichHalf) whichHalf;

@end
NS_ASSUME_NONNULL_END
