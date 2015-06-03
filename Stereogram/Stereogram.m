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
#import "UIImage+Resize.h"
#import "UIImage+Export.h"
#import "PWFunctional.h"
#import "NSError_AlertSupport.h"

static const CGFloat _thumbSize = 100;
static const CGSize _thumbnailSize = (CGSize) { .width = _thumbSize, .height = _thumbSize };

NSString *const kViewingMethod = @"ViewingMethod", *const kDateTaken = @"DateTaken";
static NSString *const LeftPhotoFileName = @"LeftPhoto.jpg", *const RightPhotoFileName = @"RightPhoto.jpg", *const PropertyListFileName = @"Properties.plist";


typedef enum WhichImage {
    LeftImage,
    RightImage
} WhichImage;




@interface Stereogram () {
    NSMutableDictionary *_properties;
    
        /// Cached images in memory. Free these if needed.
    UIImage *_stereogramImage, *_thumbnailImage;
}

/*! URL to the left image under the base URL */
@property (nonatomic, readonly) NSURL *leftImageURL;

/*! URL to the right image under the base URL */
@property (nonatomic, readonly) NSURL *rightImageURL;


@end

#pragma mark -

@implementation Stereogram

#pragma mark Class Methods

+(CGSize)thumbnailSize {
    return _thumbnailSize;
}


+(instancetype) stereogramWithDirectoryURL: (NSURL * )directoryURL
                                 leftImage: (UIImage *)leftImage
                                rightImage: (UIImage *)rightImage
                                     error: (NSError **)errorPtr {
    return [[self.class alloc] initWithDirectoryURL:directoryURL
                                          leftImage:leftImage
                                         rightImage:rightImage
                                              error:errorPtr];
}


-(instancetype) initWithDirectoryURL: (NSURL * )directoryURL
                           leftImage: (UIImage *)leftImage
                          rightImage: (UIImage *)rightImage
                               error: (NSError **)errorPtr {
        // Write the data the stereogram will read into a new stereogram 'object' (actually a directory) under errorPtr.
    NSURL *newStereogramURL = getUniqueStereogramURL(directoryURL);
    NSDictionary *propertyList = @{ kDateTaken : [NSDate date] };

        // Save the left and right images, and the property list into the directory specified by URL.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory = NO, fileExists = [fileManager fileExistsAtPath:directoryURL.path
                                                          isDirectory:&isDirectory];
    if (fileExists && !isDirectory) {
        if (errorPtr) {
            *errorPtr = [NSError errorWithDomain:kErrorDomainPhotoStore
                                            code:ErrorCode_InvalidFileFormat
                                        userInfo:@{NSLocalizedDescriptionKey : @"File exists and is not a directory.",
                                                   NSFilePathErrorKey        : directoryURL.path}];
        }
        return nil;
    }
    
        // Create the directory (ignoring any errors about it already existing).
    NSError *error = nil;
    if (![fileManager createDirectoryAtURL:newStereogramURL
               withIntermediateDirectories:NO
                                attributes:nil
                                     error:&error]) {
            // IF (error.code != TODO_DirectoryAlreadyExists)
        if (errorPtr) {
            *errorPtr = error;
        }
        return nil;
            // END IF
    }
        // Directory exists now. Add the files underneath it.
    NSURL *leftURL = [newStereogramURL URLByAppendingPathComponent:LeftPhotoFileName];
    if (!saveImageIntoURL(leftImage, leftURL, errorPtr)) {
        return nil;
    }
    
    NSURL *rightURL = [newStereogramURL URLByAppendingPathComponent:RightPhotoFileName];
    if (!saveImageIntoURL(rightImage, rightURL, errorPtr)) {
        return nil;
    }
    
    NSURL *propertyFileURL = [newStereogramURL URLByAppendingPathComponent:PropertyListFileName];
    if (!savePropertyData(propertyList, propertyFileURL, errorPtr)) {
        return nil;
    }
    return [self initWithBaseURL:newStereogramURL
                    propertyList:propertyList];
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
    for (NSURL *stereogramURL in fileNames) {
        Stereogram *stereogram = [Stereogram stereogramWithURL:stereogramURL
                                                         error:errorPtr];
        if (!stereogram) {
            return nil;
        }
        [stereogramArray addObject:stereogram];
    }
//    NSLog(@"allStereogramsUnderURL: returned %ld stereogram files: %@", (unsigned long)stereogramArray.count, stereogramArray);
    return stereogramArray;
}

+(instancetype) stereogramWithURL: (NSURL *)baseURL
                            error: (NSError **)errorPtr {
        // Return an error if any of these are missing. Also load the properties file.
    
    NSDictionary *defaultPropertyDict = @{ kViewingMethod : @(ViewingMethod_CrossEye) };
    
    NSError *error = nil;
    BOOL ok = fileExists(baseURL, LeftPhotoFileName   , &error)
    &&        fileExists(baseURL, RightPhotoFileName  , &error)
    &&        fileExists(baseURL, PropertyListFileName, &error);
    if (!ok) {
        return nil;
    }
    
        // Load the property list at the given URL.
    NSDictionary *propertyList = defaultPropertyDict;
    if (!loadPropertyList([baseURL URLByAppendingPathComponent:PropertyListFileName], &error)) {
        return nil;
    }
    return [[Stereogram alloc] initWithBaseURL:baseURL propertyList:propertyList];
}


#pragma mark - Constructors

    // Designated initializer.
-(instancetype) initWithBaseURL: (NSURL *)baseURL
                   propertyList: (NSDictionary *)propertyList {
    self = [super init];
    if (!self) { return nil; }
    
    _baseURL = baseURL;
    _properties = propertyList.mutableCopy;
    
      // Default viewing method if one wasn't found in the properties.
    if (!propertyList[kViewingMethod]) {
        self.viewingMethod = ViewingMethod_CrossEye;
    }

    _thumbnailImage = _stereogramImage = nil;
    
    NSAssert(self.viewingMethod >= 0 && self.viewingMethod < ViewingMethod_NUM_METHODS
			 , @"initWithPropertyList:leftImageURL:rightImageURL: invalid viewing method: %ld", (long)self.viewingMethod);
    
        // Notify when memory is low, so I can delete this cache.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(lowMemoryNotification:)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:nil];
    return self;
}

-(void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Callbacks

-(void) lowMemoryNotification: (NSNotification *)notification {
    NSLog(@"%@ - Low memory notification. Freeing cached images.", self);
    _thumbnailImage = nil;
    _stereogramImage = nil;
}

#pragma mark Methods


-(BOOL) deleteFromDisk: (NSError **)errorPtr {
    if (!_baseURL) {
        return YES;  // Nothing to do.
    }
//    NSLog(@"Deleting %@", _baseURL);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL success = [fileManager removeItemAtURL:_baseURL
                                          error:errorPtr];
    if (success) {
        _baseURL = nil;
        _thumbnailImage = _stereogramImage = nil;
    }
    return success;
}

-(UIImage *) stereogramImage: (NSError **)errorPtr {
        // The image is cached. Just return the cached image.
    if (_stereogramImage) {
        return _stereogramImage;
    }
    
    
        // Get the left and right images.
    NSData *leftImageData = [NSData dataWithContentsOfURL:self.leftImageURL
                                              options:0
                                                error:errorPtr];
    UIImage *leftImage = [UIImage imageWithData:leftImageData];
    if (!leftImage) {
        return nil;
    }

    NSData *rightImageData = [NSData dataWithContentsOfURL:self.rightImageURL
                                              options:0
                                                error:errorPtr];
    UIImage *rightImage = [UIImage imageWithData:rightImageData];
    if (!rightImage) {
        return nil;
    }
    
        // Create the stereogram image, cache it and return it.
    switch (self.viewingMethod) {
        case ViewingMethod_CrossEye:
            _stereogramImage = [ImageManager makeStereogramWithLeftPhoto:leftImage
                                                              rightPhoto:rightImage];
            break;
            
        case ViewingMethod_WallEye:
            _stereogramImage = [ImageManager makeStereogramWithLeftPhoto:rightImage
                                                              rightPhoto:leftImage];
            break;
            
        case ViewingMethod_AnimatedGIF:
            _stereogramImage = [UIImage animatedImageWithImages:@[leftImage, rightImage]
                                                       duration:0.25];
            break;
            
        default:
            [NSException raise:@"Not implemented"
                        format:@"Viewing method %ld is not implemented yet.", (long)self.viewingMethod];
            _stereogramImage = nil;
            break;
    }
//    NSLog(@"Stereogram %@ created stereogram image %@", self, _stereogramImage);
    return _stereogramImage;
}

-(UIImage *) thumbnailImage: (NSError **)errorPtr {
    if (!_thumbnailImage) {
        NSURL *urlToLoad = self.leftImageURL;
            // Get either the left or the right image file URL to use as the thumbnail.
        NSData *data = [NSData dataWithContentsOfURL:urlToLoad
                                             options:0
                                               error:errorPtr];
        if (!data) {
            urlToLoad = self.rightImageURL;
            data = [NSData dataWithContentsOfURL:urlToLoad
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
                                                       NSFilePathErrorKey        : urlToLoad.path }];
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




-(nullable NSData *)exportDataWithMimeType:(NSString * __nullable * __nonnull)mimeTypePtr
                                     error:(NSError * __nullable * __nullable)errorPtr {
    NSAssert(mimeTypePtr, @"MIME Type pointer was not provided.");
    
    UIImage *stereogramImage = [self stereogramImage:errorPtr];
    if (!stereogramImage) {
        return nil;
    }
    
    NSData *data;
    if (self.viewingMethod == ViewingMethod_AnimatedGIF) {
        *mimeTypePtr = @"image/gif";
        data = stereogramImage.asGIFData;
    } else {
        *mimeTypePtr = @"image/jpeg";
        data = stereogramImage.asJPEGData;
    }
    return data;
}



-(BOOL) refresh: (NSError **)errorPtr {
    _thumbnailImage = nil;
    _stereogramImage = nil;
    
    if (![self thumbnailImage:errorPtr]) {
        return NO;
    }
    if (![self stereogramImage:errorPtr]) {
        return NO;
    }
    return YES;
}

#pragma mark Properties

/*! The URL to the left image under the object's base URL. */

-(NSURL *)leftImageURL {
    return [_baseURL URLByAppendingPathComponent:LeftPhotoFileName];
}

/*! The URL to the right image under the object's base URL. */

-(NSURL *)rightImageURL {
    return [_baseURL URLByAppendingPathComponent:RightPhotoFileName];
}

-(NSString *)description {
    NSString *description = [NSString stringWithFormat:@"%@ <viewingMethod = %ld, baseURL = %@, Proprty Dict = %@>"
                             , super.description, (long)self.viewingMethod, _baseURL, _properties];
    return description;
}

/*!
 * Return the current viewing method of this stereogram.
 *
 * This determines the type of image that stereogramImage: will return.
 */

-(enum ViewingMethod) viewingMethod {
    NSNumber *viewingMethodNumber = _properties[kViewingMethod];
    return (enum ViewingMethod)viewingMethodNumber.integerValue;
}

/*!
 * Store the current viewing method of this stereogram.
 *
 * This determines the type of image that stereogramImage: will return.
 *
 * @param viewingMethod The method for creating the stereogram image.
 */

-(void) setViewingMethod: (enum ViewingMethod)viewingMethod {
    if (viewingMethod != self.viewingMethod) {
        NSNumber *viewingMethodNumber = [NSNumber numberWithInteger:viewingMethod];
        _properties[kViewingMethod] = viewingMethodNumber;
        [self saveProperties:nil];
        
            // Force a reload of the cached images once the viewing method changes.
        _thumbnailImage = nil;
        _stereogramImage = nil;
    }
}


#pragma mark Private 

/*!
 * Return a URL pointing to a unique file name under photoDir.
 *
 * Create a CF GUID, then turn it into a string, which we will return.
 * This should guarantee that each filename will be unique and we won't have crossovers.
 *
 * @param photoDir Directory to store the stereogram in.
 * @return A URL pointing to the where the new stereogram file should be stored.
 */
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
	if (!image) {
		if (errorPtr) {
			*errorPtr = [NSError parameterErrorWithNilParameter:@"image"];
		}
		return NO;
	}
    NSData *fileData = UIImageJPEGRepresentation(image, 1.0);
    return [fileData writeToURL:url
                        options:NSDataWritingAtomic
                          error:errorPtr];
}

/*!
 * Writes the property dict back to disk, overwriting the current property file for this stereogram.
 *
 * @param errorPtr Pointer to return error information to the caller.
 * @return YES if save succeeded, NO if something went wrong.
 */

-(BOOL) saveProperties: (NSError **)errorPtr {
    return savePropertyData(_properties, [_baseURL URLByAppendingPathComponent:PropertyListFileName], errorPtr);
}

/*!
 * Writes property data provided into a file at a given URL.
 *
 * @param propertyDict A Dictionary of properties. Must contain only Apple property-list objects.
 * @param propertyFileURL A File URL to a place to store the property data. Default file extension should be .plist
 * @param errorPtr        An output pointer for returning error information to the caller.
 * @return YES on success, NO on failure.
 */

static BOOL savePropertyData(NSDictionary *propertyDict, NSURL *propertyFileURL, NSError **errorPtr) {
    NSData *propertyListData = [NSPropertyListSerialization dataWithPropertyList:propertyDict
                                                                          format:NSPropertyListXMLFormat_v1_0
                                                                         options:0
                                                                           error:errorPtr];
    if (!propertyListData) {
        return NO;
    }
    
    if (![propertyListData writeToURL:propertyFileURL
                              options:NSDataWritingAtomic
                                error:errorPtr]) {
        return NO;
    }
    return YES; // Success.
}

/*!
 * Checks if a file exists given a base directory URL and filename.
 *
 * @param baseURL  The Base URL to look in.
 * @param fileName The name of the file to check for.
 * @param errorPtr Pointer to return errors to the caller.
 * @return YES if the file was present, NO if it was not.
 */

static BOOL fileExists(NSURL *baseURL, NSString *fileName, NSError **errorPtr) {
    NSString *fullURLPath = [baseURL URLByAppendingPathComponent:fileName].path;
    if ([[NSFileManager defaultManager] fileExistsAtPath:fullURLPath]) {
        return YES;
    }
    
    if (errorPtr) {
        NSDictionary *userInfo = @{ NSFilePathErrorKey : fullURLPath ? fullURLPath : @"<no path>" };
        NSError *error = [NSError errorWithDomain: kErrorDomainPhotoStore code: ErrorCode_FileNotFound userInfo: userInfo];
        *errorPtr = error;
    }
    return NO;
}

/*! Load a property list stored at URL and return it.
 *
 * @param url File URL describing a path to a .plist file.
 * @param errorPtr
 * @return A Dictionary on success, nil on failure.
 */
NSDictionary *loadPropertyList(NSURL *url, NSError **errorPtr) {
    NSData *propertyData = [NSData dataWithContentsOfURL:url options:0 error:errorPtr];
    if (propertyData) {
        NSInteger options = NSPropertyListMutableContainersAndLeaves;
        NSMutableDictionary *propObject = [NSPropertyListSerialization propertyListWithData:propertyData
                                                                                    options:options
                                                                                     format:nil
                                                                                      error:errorPtr];
        NSCAssert(propObject != nil, @"Property list object %@ cannot be converted to a dictionary", propObject);
        return propObject;
    }
    return nil;
}


@end
