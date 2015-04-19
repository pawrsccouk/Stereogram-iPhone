//
//  Stereogram.m
//  Stereogram
//
//  Created by Patrick Wallace on 15/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

#import "Stereogram.h"
#import "ErrorData.h"
#import "ImageManager.h"
#import "ThumbnailCache.h"
#import "UIImage+Resize.h"
#import "PWFunctional.h"

static const CGFloat _thumbSize = 100;
static const CGSize _thumbnailSize = (CGSize) { .width = _thumbSize, .height = _thumbSize };

NSString *const kViewingMethod = @"ViewingMethod";
static NSString *const LeftPhotoFileName = @"LeftPhoto.jpg", *const RightPhotoFileName = @"RightPhoto.jpg", *const PropertyListFileName = @"Properties.plist";


typedef NS_ENUM(NSInteger, WhichImage) {
    LeftImage,
    RightImage
};

@interface Stereogram () {
        // URLs to the left and right images. Used to load the images when needed.
    NSURL *_leftImageURL, *_rightImageURL;
    NSMutableDictionary *_properties;
    
        /// Cached images in memory. Free these if needed.
    UIImage *_leftImage, *_rightImage, *_stereogramImage, *_thumbnailImage;
}

@end

#pragma mark -

@implementation Stereogram

#pragma mark Class Methods

+(CGSize)thumbnailSize {
    return _thumbnailSize;
}


+(instancetype) createAndSaveFromLeftImage: (UIImage *)leftImage
                                rightImage: (UIImage *)rightImage
                                   baseURL: (NSURL *)baseURL
                                     error: (NSError **)errorPtr {
    NSURL *newStereogramURL = getUniqueStereogramURL(baseURL);
    NSDictionary *propertyList = @{};
    NSArray *urls = writeToURL(newStereogramURL, propertyList, leftImage, rightImage, errorPtr);
    if (!urls) {
        return nil;
    }
    NSAssert(urls.count == 2, @"Invalid URL array %@ returned from writeToURL.", urls);
    return [[self alloc] initWithPropertyList:propertyList.mutableCopy
                                 leftImageURL:urls[0]
                                rightImageURL:urls[1]];
}


    // Return all the image URLs in the image directory.
+(NSArray *) allStereogramsUnderURL: (NSURL *)url
                              error: (NSError **)errorPtr {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *fileNames = [fileManager contentsOfDirectoryAtURL:url
                                    includingPropertiesForKeys:nil
                                                       options:NSDirectoryEnumerationSkipsHiddenFiles
                                                         error:errorPtr];
    
    NSMutableArray *stereogramArray = [NSMutableArray array];
    for (NSURL *url in fileNames) {
        Stereogram *stereogram = [[Stereogram alloc] initWithURL:url
                                                           error:errorPtr];
        if (!stereogram) {
            return nil;
        }
        [stereogramArray addObject:stereogram];
    }
    NSLog(@"allStereogramsUnderURL: returned %ld stereogram files: %@", (unsigned long)stereogramArray.count, stereogramArray);
    return stereogramArray;
}


#pragma mark - Constructors

    // Designated initializer.
-(instancetype) initWithPropertyList: (NSMutableDictionary *)propertyList
                        leftImageURL: (NSURL *)leftImageURL
                       rightImageURL: (NSURL *)rightImageURL {
    self = [super init];
    if (!self) { return nil; }
    
    _leftImageURL = leftImageURL;
    _rightImageURL = rightImageURL;
    _properties = propertyList;
    self.viewingMethod = ViewingMethod_CrossEye;  // Default

    _leftImage = _rightImage = _thumbnailImage = _stereogramImage = nil;
    
    NSAssert(self.viewingMethod >= 0 && self.viewingMethod < ViewingMethod_NUM_METHODS, @"initWithPropertyList:leftImageURL:rightImageURL: invalid viewing method: %ld", (long)self.viewingMethod);
    
        // Notify when memory is low, so I can delete this cache.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(lowMemoryNotification:)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:nil];
    return self;
}

-(instancetype) initWithURL: (NSURL *)url
                      error: (NSError **)errorPtr {
    
        // URL should be pointing to a directory. Inside this there should be 3 files: LeftImage.jpg, RightImage.jpg, properties.plist
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *directoryContents = [fileManager contentsOfDirectoryAtURL:url
                                            includingPropertiesForKeys:nil
                                                               options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                 error:errorPtr];
    if (!directoryContents) {
        return nil;  // init failed. *errorPtr has the info.
    }
    NSMutableDictionary *propertyList = nil;
    NSURL *leftImageURL = nil, *rightImageURL = nil;
    for (NSURL *componentURL in directoryContents) {
        if ([componentURL.lastPathComponent isEqualToString:LeftPhotoFileName]) {
            leftImageURL = componentURL.copy;
        } else if ([componentURL.lastPathComponent isEqualToString:RightPhotoFileName]) {
            rightImageURL = componentURL.copy;
        } else if ([componentURL.lastPathComponent isEqualToString:PropertyListFileName]) {
            NSData *propertyData = [NSData dataWithContentsOfURL:componentURL
                                                          options:0
                                                            error:errorPtr];
            if (!propertyData) {
                return nil;  // errorPtr has the error data.
            }
            propertyList = [NSPropertyListSerialization propertyListWithData:propertyData
                                                                     options:NSPropertyListMutableContainersAndLeaves
                                                                      format:NULL
                                                                       error:errorPtr];
            if (!propertyList) {
                return nil; // errorPtr has the error data.
            }
        } else {
            NSLog(@"Unknown component %@ found in Stereogram directory %@", componentURL.lastPathComponent, url);
        }
    }
    NSAssert(leftImageURL,  @"Missing leftImageURL after initWithURL:error for URL of %@", url);
    NSAssert(rightImageURL, @"Missing rightImageURL after initWithURL:error for URL of %@", url);
    return [self initWithPropertyList:propertyList
                         leftImageURL:leftImageURL
                        rightImageURL:rightImageURL];
}


-(void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Callbacks

-(void) lowMemoryNotification: (NSNotification *)notification {
    _leftImage = nil;
    _rightImage = nil;
    _thumbnailImage = nil;
    _stereogramImage = nil;
}

#pragma mark Methods


-(BOOL) deleteFromDisk: (NSError **)errorPtr {
    NSURL *sampleURL = _leftImageURL ? _leftImageURL : _rightImageURL;
    if (!sampleURL) {
        return YES;  // Nothing to do.
    }
    NSURL *objectFolderURL = sampleURL.URLByDeletingLastPathComponent;
    NSLog(@"Deleting %@", objectFolderURL);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL success = [fileManager removeItemAtURL:objectFolderURL
                                          error:errorPtr];
    if (success) {
        _leftImageURL = _rightImageURL = nil;
        _thumbnailImage = _stereogramImage = _leftImage = _rightImage = nil;
    }
    return success;
}

-(UIImage *) stereogramImage: (NSError **)errorPtr {
        // The image is cached. Just return the cached image.
    if (_stereogramImage) {
        return _stereogramImage;
    }
        // Get the left and right images, loading them if they are not in cache.
    if (!_leftImage) {
        _leftImage = [self loadImage:LeftImage
                               error:errorPtr];
    }
    if (!_leftImage) {
        return nil;
    }
    if (!_rightImage) {
        _rightImage = [self loadImage:RightImage
                                error:errorPtr];
    }
    if (!_rightImage) {
        return nil;
    }
    
        // Create the stereogram image, cache it and return it.
    switch (self.viewingMethod) {
        case ViewingMethod_CrossEye:
            _stereogramImage = [ImageManager makeStereogramWithLeftPhoto:_leftImage
                                                             rightPhoto:_rightImage];
            break;
            
        case ViewingMethod_WallEye:
            _stereogramImage = [ImageManager makeStereogramWithLeftPhoto:_rightImage
                                                             rightPhoto:_leftImage];
            break;
            
        default:
            [NSException raise:@"Not implemented"
                        format:@"Viewing method %ld is not implemented yet.", (long)self.viewingMethod];
            _stereogramImage = nil;
            break;
    }
    NSLog(@"Stereogram %@ created stereogram image %@", self, _stereogramImage);
    return _stereogramImage;
}

-(UIImage *) thumbnailImage: (NSError **)errorPtr {
    if (!_thumbnailImage) {
            // Get either the left or the right image file URL to use as the thumbnail.
        NSData *data = [NSData dataWithContentsOfURL:_leftImageURL
                                             options:0
                                               error:errorPtr];
        if (!data) {
            data = [NSData dataWithContentsOfURL:_rightImageURL
                                         options:0
                                           error:errorPtr];
        }
        if (!data) {
            return nil;
        }
        
            // Create the image, and then return a thumbnail-sized copy.
        UIImage *image = [UIImage imageWithData:data];
        if (!image) {
            if (errorPtr) {
                *errorPtr = [NSError errorWithDomain:kErrorDomainPhotoStore
                                                code:ErrorCode_InvalidFileFormat
                                            userInfo:@{NSLocalizedDescriptionKey : @"Invalid image format in file",
                                                       NSFilePathErrorKey        : _leftImageURL.path }];
            }
            return nil;
        }
        _thumbnailImage = [image thumbnailImage:_thumbSize
                              transparentBorder:0
                                   cornerRadius:0
                           interpolationQuality:kCGInterpolationLow];

    }
    NSLog(@"Stereogram %@ created thumbnail image %@", self, _thumbnailImage);
    return _thumbnailImage;
}

-(BOOL) refresh:(NSError **)errorPtr {
    NSLog(@"Refreshing stereogram %@", self);
    _thumbnailImage = nil;
    _stereogramImage = nil;
    _leftImage = nil;
    _rightImage = nil;
    
    if (![self thumbnailImage:errorPtr]) {
        return NO;
    }
    if (![self stereogramImage:errorPtr]) {
        return NO;
    }
    return YES;
}

#pragma mark Properties

-(NSString *)description {
    NSString *description = [NSString stringWithFormat:@"%@ <viewingMethod = %ld, leftURL = %@, rightURL = %@>"
                             , super.description, (long)self.viewingMethod, _leftImageURL, _rightImageURL];
    return description;
}

-(ViewingMethod) viewingMethod {
    NSNumber *viewingMethodNumber = _properties[kViewingMethod];
    return viewingMethodNumber.integerValue;
}

-(void)setViewingMethod:(ViewingMethod)viewingMethod {
    if (viewingMethod != self.viewingMethod) {
        NSNumber *viewingMethodNumber = [NSNumber numberWithInteger:viewingMethod];
        _properties[kViewingMethod] = viewingMethodNumber;
            // Force a reload of the cached images once the viewing method changes.
        _thumbnailImage = nil;
        _stereogramImage = nil;
    }
}

#pragma mark Private 

    // Create a CF GUID, then turn it into a string, which we will return.
    // Add the object into the backing store using this key.
static NSURL *getUniqueStereogramURL(NSURL *photoDir) {
    if (!photoDir) { return nil; }
    
    CFUUIDRef newUID = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef newUIDString = CFUUIDCreateString(kCFAllocatorDefault, newUID);
    
        // The __bridge in this cast means ARC won't do any allocing or releasing of the string produced by the cast.
        // So I can only use it before CFRelease() is called on it.  URLByAppendingPathComponent makes a new string based on it.
        // I.e. I can only use it in this function (or pass it to some other object which will retain it)
    NSURL *newURL = [photoDir URLByAppendingPathComponent:(__bridge NSString *)newUIDString
                                              isDirectory:YES];
    CFRelease(newUIDString);
    CFRelease(newUID);
    
        // Name should be unique so no photo should exist yet.
    NSCAssert(![[NSFileManager defaultManager] fileExistsAtPath:newURL.path], @"'Unique' file URL %@ already exists", newURL);
    return newURL;
}

static BOOL saveImageIntoURL(UIImage *image, NSURL *url, NSError **errorPtr) {
    NSData *fileData = UIImageJPEGRepresentation(image, 1.0);
    return [fileData writeToURL:url
                        options:NSDataWritingAtomic
                          error:errorPtr];
}

static NSArray *writeToURL(NSURL *url, NSDictionary *propertyList, UIImage *leftImage, UIImage *rightImage, NSError **errorPtr) {
    NSLog(@"writeToURL: url = %@", url);
        // Save the left and right images, and the property list into the directory specified by URL.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory = NO, fileExists = [fileManager fileExistsAtPath:url.path
                                                          isDirectory:&isDirectory];
    if (fileExists && !isDirectory) {
        if (errorPtr) {
            *errorPtr = [NSError errorWithDomain:kErrorDomainPhotoStore
                                            code:ErrorCode_InvalidFileFormat
                                        userInfo:@{NSLocalizedDescriptionKey : @"File exists and is not a directory.",
                                                   NSFilePathErrorKey        : url.path}];
        }
        return nil;
    }
    
        // Create the directory (ignoring any errors about it already existing).
    NSError *error = nil;
    if (![fileManager createDirectoryAtURL:url
               withIntermediateDirectories:NO
                                attributes:nil
                                     error:&error]) {
            // if (error.code != TODO_DirectoryAlreadyExists) {
        if (errorPtr) {
            *errorPtr = error;
        }
        return nil;
            // }
    }
        // Directory exists now. Add the files underneath it.
    NSURL *leftImageURL = [url URLByAppendingPathComponent:LeftPhotoFileName];
    if (!saveImageIntoURL(leftImage, leftImageURL, errorPtr)) {
        return nil;
    }
    
    NSURL *rightImageURL = [url URLByAppendingPathComponent:RightPhotoFileName];
    if (!saveImageIntoURL(rightImage, rightImageURL, errorPtr)) {
        return nil;
    }
    
    NSData *propertyListData = [NSPropertyListSerialization dataWithPropertyList:propertyList
                                                                          format:NSPropertyListXMLFormat_v1_0
                                                                         options:0
                                                                           error:errorPtr];
    if (!propertyListData) {
        return nil;
    }
    
    NSURL *propertyListURL = [url URLByAppendingPathComponent:PropertyListFileName];
    if (![propertyListData writeToURL:propertyListURL
                              options:NSDataWritingAtomic
                                error:errorPtr]) {
        return nil;
    }
    return @[leftImageURL, rightImageURL]; // Success. Return the URLs of the left and right images.
}



-(UIImage *) loadImage: (WhichImage)whichImage
                 error: (NSError **)errorPtr {
    switch (whichImage) {
        case LeftImage:
            if (!_leftImage) {
                NSData *imageData = [NSData dataWithContentsOfURL:_leftImageURL
                                                          options:0
                                                            error:errorPtr];
                if (!imageData) {
                    return nil;
                }
                _leftImage = [UIImage imageWithData:imageData];
            }
            return _leftImage;
        case RightImage:
            if (!_rightImage) {
                NSData *imageData = [NSData dataWithContentsOfURL:_rightImageURL
                                                          options:0
                                                            error:errorPtr];
                _rightImage = [UIImage imageWithData:imageData];
            }
            return _rightImage;
    }
}


@end
