//
//  PWPhotoStore.h
//  Stereogram
//
//  Created by Patrick Wallace on 20/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import <Foundation/Foundation.h>


// Error domain and codes for the Photo Store.

static NSString * const kPWErrorDomainPhotoStore;

enum PWErrorCodes {
    kPWErrorCodesUnknownError             =   1,
    kPWErrorCodesCouldntCreateSharedStore = 100,
    kPWErrorCodesCouldntLoadImageProperties    ,
    kPWErrorCodesIndexOutOfBounds
};

    // How the stereogram should be viewed.
enum PWViewModes {
    PWViewModeCrosseyed,    // Adjacent pictures, view crosseyed.
    PWViewModeWalleyed,     // Adjacent pictures, view wall-eyed
    PWViewModeRedGreen,     // Superimposed pictures, use red green glasses.
    PWViewModeRandomDot     // "Magic Eye" format.
};


// Most methods return an NSError *. These return nil on success or an NSError object on failure.

// Methods that return something take an NSError* error argument. These methods return the object on success or nil on failure,
// in which case they also set the *error to indicate what went wrong, if error is not NULL.

@interface PWPhotoStore : NSObject

    // Number of images stored in here.
@property (nonatomic, readonly) NSUInteger count;

    // Size of a thumbnail in pixels.  Thumbnails are square, so this is the width and the height of it.
@property (nonatomic, readonly) NSUInteger thumbnailSize;


    // This class method should be called before the store is first used.
    // I've put some setup here that requires an error object, so the user gets a chance to see the error.
+(NSError *)setupStore;

    // Returns the shared pointer used by all accessors of the store. NB the store is not thread-safe yet.
+(PWPhotoStore*)sharedStore;

    // Save the image property file.
-(NSError*) saveProperties;

#pragma mark - Handling images

    // Attempts to add the image to the store. dateTaken is when the original photo was taken, which is added to the properties.
-(NSError *)addImage:(UIImage*)image dateTaken:(NSDate*) dateTaken;

    // Retrieves the image in the collection which is at index position <index>.
-(UIImage *)imageAtIndex:(NSUInteger)index error:(NSError**)error;

    // Like imageAtIndex but receives a smaller thumbnail image.
-(UIImage *)thumbnailAtIndex:(NSUInteger)index error:(NSError**)error;

    // Compose the two photos given to make a stereogram.
-(UIImage *)makeStereogramWith:(UIImage *)leftPhoto and:(UIImage *)rightPhoto;

    // Deletes the images at the specified index paths.
-(NSError *)deleteImagesAtIndexPaths:(NSArray*)indexPaths;

    // Overwrites the image at the given position with a new image.
    // Returns an error if there is no image at index already.
-(NSError *)replaceImageAtIndex:(NSUInteger)index withImage:(UIImage*)newImage;

    // Copies the image at position <index> into the camera roll.
-(NSError *)copyImageToCameraRoll:(NSUInteger)index;

    // Toggles the viewing method from crosseye to walleye and back for the image at position <index>.
-(NSError *)changeViewingMethod:(NSUInteger) index;

@end
