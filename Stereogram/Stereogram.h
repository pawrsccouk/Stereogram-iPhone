//
//  Stereogram.h
//  Stereogram
//
//  Created by Patrick Wallace on 15/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

#import <Foundation/Foundation.h>

    /// The ways of displaying 'self.fullImage'.
typedef NS_ENUM(NSInteger, ViewingMethod) {
    ViewingMethod_CrossEye,
    ViewingMethod_WallEye,
    ViewingMethod_AnimatedGIF,
    
    ViewingMethod_NUM_METHODS
};

    /// This holds data for one stereogram and can load and save it if given a file URL.

@interface Stereogram : NSObject

    /// Size of the thumbnails that thumbnailImage will provide.
+(CGSize) thumbnailSize;

    /// Allocate a filename for this object, save both images under it, and then create and return a new Stereogram with the URLs of those saved images. baseURL is the directory to put the new object in.
+(instancetype) createAndSaveFromLeftImage: (UIImage *)leftImage
                                rightImage: (UIImage *)rightImage
                                   baseURL: (NSURL *)baseURL
                                     error: (NSError **)errorPtr;

    /// Load all the stereograms in the global stereogram directory and return them in an array.
+(NSArray *) allStereogramsUnderURL: (NSURL*)url
                              error: (NSError **)errorPtr;

#pragma mark -

@property (nonatomic) ViewingMethod viewingMethod;

    /// Combine leftImage and rightImage according to viewingMethod, loading the images if they are not already available.
-(UIImage *) stereogramImage: (NSError **)errorPtr;

    /// Return a thumbnail image, caching it if necessary.
-(UIImage *) thumbnailImage: (NSError **)errorPtr;

    /// Update the stereogram and thumbnail, replacing the cached images.  Usually called from a background thread just after some property has been changed.
-(BOOL) refresh: (NSError **)errorPtr;

    /// Delete the folder representing this error from the disk.
-(BOOL) deleteFromDisk: (NSError **)errorPtr;

#pragma mark Initializers

    /// Convenience initializer. Initialize this object by loading image data from the specified URL.  If the init fails, returns nil, and sets *errorPtr to an error object indicating what went wrong.
-(instancetype) initWithURL: (NSURL *)url
                      error: (NSError **)errorPtr;

    /// Designated initializer. Initialize this object with a left and a right image and a viewing mode.

-(instancetype) initWithPropertyList: (NSMutableDictionary *)propertyList
                        leftImageURL: (NSURL *)leftImage
                       rightImageURL: (NSURL *)rightImage NS_DESIGNATED_INITIALIZER;


@end
