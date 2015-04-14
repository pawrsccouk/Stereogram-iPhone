//
//  ThumbnailCache.h
//  Stereogram
//
//  Created by Patrick Wallace on 10/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

#import <Foundation/Foundation.h>

    /// Stores a collection of image thumbnails, with code to generate and cache them.
@interface ThumbnailCache : NSObject

    /// Size of a thumbnail in pixels.  Thumbnails are square.
@property (nonatomic, readonly) CGSize thumbnailSize;

    /// Returns a thumbnail for the image specified by key (the path to the image file on disk). If there is no thumbnail yet, creates one and adds it to the cache.
-(UIImage *) thumbnailForKey: (NSString *)key
                       error: (NSError **)errorPtr;

    /// Create a thumbnail for the image provided and add it to the thumbnail cache under the specified key, which is the full path to the real image on disk.  Returns the thumbnail if successful.
-(UIImage *) addThumbnailForImage: (UIImage *)image
                           forKey: (NSString *)path;


@end
