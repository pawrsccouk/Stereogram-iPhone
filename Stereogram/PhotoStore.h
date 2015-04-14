//
//  PhotoStore.h
//  Stereogram
//
//  Created by Patrick Wallace on 20/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark Error domain and codes

extern NSString *const PhotoStoreErrorDomain;

typedef NS_ENUM(NSInteger, ErrorCode) {
    PhotoStoreErrorCodeUnknownError             =   1,
    PhotoStoreErrorCodeCouldntCreateSharedStore = 100,
    PhotoStoreErrorCodeCouldntLoadImageProperties    ,
    PhotoStoreErrorCodeIndexOutOfBounds              ,
    PhotoStoreErrorCodeCouldntCreateStereogram
};

    // How the stereogram should be viewed.
enum ViewModes {
    ViewModeCrosseyed,    // Adjacent pictures, view crosseyed.
    ViewModeWalleyed,     // Adjacent pictures, view wall-eyed
    ViewModeRedGreen,     // Superimposed pictures, use red green glasses.
    ViewModeRandomDot     // "Magic Eye" format.
};


// Methods take an NSError* error argument. These methods return the object on success or nil on failure, in which case they also set the *error to indicate what went wrong, if error is not NULL.  Methods that don't return a value return YES or NO and set *error.

@interface PhotoStore : NSObject

    /// Number of images stored in here.
@property (nonatomic, readonly) NSUInteger count;

    /// Size of an image thumbnail.
@property (nonatomic, readonly) CGSize thumbnailSize;

    /// Constructor. If something fails it returns nil and an error.
-(instancetype)init: (NSError **)error NS_DESIGNATED_INITIALIZER;

    /// Save the image property file.
-(BOOL) saveProperties: (NSError **)errorPtr;

#pragma mark - Handling images

    /// Attempts to add the image to the store. dateTaken is when the original photo was taken, which is added to the properties.
-(BOOL) addImage:(UIImage*)image
       dateTaken:(NSDate*) dateTaken
           error:(NSError **)errorPtr;

    /// Retrieves the image in the collection which is at index position <index>.
-(UIImage *)imageAtIndex:(NSUInteger)index
                   error:(NSError**)error;

    /// Like imageAtIndex but receives a smaller thumbnail image.
-(UIImage *) thumbnailAtIndex: (NSUInteger)index
                        error: (NSError**)error;


    /// Deletes the images at the specified index paths.
-(BOOL) deleteImagesAtIndexPaths: (NSArray*)indexPaths
                           error:(NSError **)errorPtr;

    /// Overwrites the image at the given position with a new image.
    /// Returns an error if there is no image at index already.
-(BOOL) replaceImageAtIndex:(NSUInteger)index withImage:(UIImage*)newImage error:(NSError **)errorPtr;

    /// Copies the image at position <index> into the camera roll.
-(BOOL) copyImageToCameraRoll:(NSUInteger)index error:(NSError **)errorPtr;


@end
