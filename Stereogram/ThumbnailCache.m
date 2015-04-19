////
////  ThumbnailCache.m
////  Stereogram
////
////  Created by Patrick Wallace on 21/01/2015.
////  Copyright (c) 2015 Patrick Wallace. All rights reserved.
////
//
//#import <UIKit/UIKit.h>
//#import "ThumbnailCache.h"
//#import "ImageManager.h"
//#import "UIImage+Resize.h"
//
//static const CGFloat _thumbSize = 100;
//static const CGSize _thumbnailSize = (CGSize) { .width = _thumbSize, .height = _thumbSize };
//
//@interface ThumbnailCache () {
//    NSMutableDictionary *_thumbnailDict;  // Key = NSString, Value = UIImage
//}
//@end
//
//@implementation ThumbnailCache
//
//- (instancetype)init {
//    self = [super init];
//    if (!self) { return nil; }
//    
//    _thumbnailDict = [NSMutableDictionary dictionary];
//    
//        // Notify when memory is low, so I can delete this cache.
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(lowMemoryNotification:)
//                                                 name:UIApplicationDidReceiveMemoryWarningNotification
//                                               object:nil];
//    return self;
//}
//
//- (void)dealloc {
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
//}
//
//
//-(void) freeCache {
//    [_thumbnailDict removeAllObjects];
//}
//
//- (CGSize)thumbnailSize {
//    return _thumbnailSize;
//}
//
//    // Returns a thumbnail for the image specified by filePath (the path to the image file on disk). If there is no thumbnail yet, creates one and adds it to the cache.
//    // If successful, returns .Success(the-thumbnail), otherwise returns an error.
//-(UIImage *) thumbnailForKey: (NSString *)key
//                       error: (NSError **)errorPtr {
//    UIImage *thumb = _thumbnailDict[key];
//    if (thumb) { return thumb; } // Success, return the cached image.
//    
//        // If the thumbnail was not already cached, create it and return it now.
//    thumb = [ImageManager imageFromFile:key error:errorPtr];
//    if (!thumb) { return nil; }
//    return [self addThumbnailForImage:thumb forKey:key];
//}
//
//
//
//    // Create a thumbnail for the image provided and add it to the thumbnail cache under the specified key, which is the full path to the real image on disk.
//    // Returns the thumbnail if successful.
//-(UIImage *) addThumbnailForImage: (UIImage *)image
//                           forKey: (NSString *)key {
//        // Use the left half of the image for the thumbnail, as having both makes the actual image content too small to see.
//    UIImage *leftHalf = [ImageManager getHalfOfImage:image whichHalf:LeftHalf];
//    if (!leftHalf) { return nil; }
//    UIImage *thumbnail = [leftHalf thumbnailImage:_thumbSize transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationLow];
//    if (!thumbnail) { return nil; }
//    _thumbnailDict[key] = thumbnail;
//    return thumbnail;
//}
//
//@end
