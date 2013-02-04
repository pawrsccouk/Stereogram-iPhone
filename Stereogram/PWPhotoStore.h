//
//  PWPhotoStore.h
//  Stereogram
//
//  Created by Patrick Wallace on 20/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PWPhotoStore : NSObject
{
    NSMutableDictionary *thumbnailCache;
    NSMutableArray      *storedFilenames;
    NSString *photoFolderPath;
}

    // Number of images stored in here.
@property (nonatomic, readonly) NSUInteger count;

    // Size of a thumbnail in pixels.  Thumbnails are square, so this is the width and the height of it.
@property (nonatomic, readonly) NSUInteger thumbnailSize;


    // This class method should be called before the store is first used.
    // I've put some setup here that requires an error object, so the user gets a chance to see the error.
    // Returns YES if it succeeded, NO and sets *error to an NSError if it fails.
+(BOOL)setupStore:(NSError**)error;

    // Returns the shared pointer used by all accessors of the store. NB the store is not thread-safe yet.
+(PWPhotoStore*)sharedStore;

    // Attempts to add the image to the store. Returns YES if successful, NO and sets *error on failure.
-(BOOL)addImage:(UIImage*)image error:(NSError**)error;

    // Retrieves the image in the collection which is at index position <index>.
    // If this fails, returns nil and puts an error into *error if provided.
-(UIImage *)imageAtIndex:(NSUInteger)index error:(NSError**)error;

    // Like imageAtIndex but receives a smaller thumbnail image.
-(UIImage *)thumbnailAtIndex:(NSUInteger)index error:(NSError**)error;

    // Compose the two photos given to make a stereogram 
-(UIImage *)makeStereogramWith:(UIImage *)firstPhoto and:(UIImage *)secondPhoto;

    // Deletes the images at the specified index paths. Returns YES if successful, NO and sets *error on failure.
-(BOOL)deleteImagesAtIndexPaths:(NSArray*)indexPaths error:(NSError**)error;

    // Copies the image at position <index> into the camera roll. Returns YES if successful, NO and sets *error on failure.
-(BOOL)copyImageToCameraRoll:(NSUInteger)index error:(NSError**)error;

@end
