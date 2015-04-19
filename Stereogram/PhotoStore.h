//
//  PhotoStore.h
//  Stereogram
//
//  Created by Patrick Wallace on 20/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Stereogram;

#pragma mark Error domain and codes

extern NSString *const PhotoStoreErrorDomain;

typedef NS_ENUM(NSInteger, PhotoStoreErrorCodes) {
    PhotoStoreErrorCode_UnknownError             =   1,
    PhotoStoreErrorCode_CouldntCreateSharedStore = 100,
    PhotoStoreErrorCode_CouldntLoadImageProperties    ,
    PhotoStoreErrorCode_IndexOutOfBounds              ,
    PhotoStoreErrorCode_CouldntCreateStereogram
};

    // How the stereogram should be viewed.
typedef NS_ENUM(NSInteger, ViewModes) {
    ViewMode_Crosseyed,    // Adjacent pictures, view crosseyed.
    ViewMode_Walleyed,     // Adjacent pictures, view wall-eyed
    ViewMode_RedGreen,     // Superimposed pictures, use red green glasses.
    ViewMode_RandomDot,    // "Magic Eye" format.
    ViewMode_AnimatedGIF
};


// Methods take an NSError* error argument. These methods return the object on success or nil on failure, in which case they also set the *error to indicate what went wrong, if error is not NULL.  Methods that don't return a value return YES or NO and set *error.

@interface PhotoStore : NSObject

    /// Number of stereograms stored in here.
@property (nonatomic, readonly) NSUInteger count;

    /// Size of an image thumbnail.
@property (nonatomic, readonly) CGSize thumbnailSize;

    /// Constructor. If something fails it returns nil and an error.
-(instancetype) init: (NSError **)error NS_DESIGNATED_INITIALIZER;

#pragma mark - Handling stereograms

    /// Adds the stereogram to the store. Assumes the stereogram has already been successfully created and saved.
-(void) addStereogram: (Stereogram *)stereogram;

    /// Creates a new stereogram from the images provided, then saves it, adds it to this collection and returns it.
-(Stereogram *) createStereogramFromLeftImage: (UIImage *)leftImage
                                   rightImage: (UIImage *)rightImage
                                        error: (NSError **)errorPtr;

    /// Retrieves the stereogram in the collection which is at index position <index>.
-(Stereogram *) stereogramAtIndex: (NSUInteger)index;

    /// Deletes the stereograms at the specified index paths.
-(BOOL) deleteStereogramsAtIndexPaths: (NSArray *)indexPaths
                                error: (NSError **)errorPtr;

    /// Given a stereogram object, attempt to delete it from disk and remove it from this collection.
-(BOOL) deleteStereogram: (Stereogram *)stereogram
                   error: (NSError **)errorPtr;

    /// Overwrites the stereogram at the given position with a new image.
    /// Returns an error if there is no stereogram at index already.
-(BOOL) replaceStereogramAtIndex: (NSUInteger)index
                  withStereogram: (Stereogram *)newImage
                           error: (NSError **)errorPtr;

    /// Copies the stereogram at position <index> into the camera roll.
-(BOOL) copyStereogramToCameraRoll: (NSUInteger)index
                             error: (NSError **)errorPtr;
@end
