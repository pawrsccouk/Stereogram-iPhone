//
//  PhotoStore.m
//  Stereogram
//
//  Created by Patrick Wallace on 20/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import "PhotoStore.h"
#import "PWFunctional.h"
#import "UIImage+Resize.h"
#import "ErrorData.h"
#import "ThumbnailCache.h"
#import "ImageManager.h"

NSString *const PhotoStoreErrorDomain = @"PhotoStore";

    // Viewing method for the image.
typedef NS_ENUM(NSUInteger, ViewingMethod) { ViewingMethodCrosseye, ViewingMethodWalleye };

static NSError *makeUnknownError() {
    return [NSError errorWithDomain:kErrorDomainPhotoStore
                               code:ErrorCodesUnknownError
                           userInfo:@{ (NSString*)kCFErrorDescriptionKey : @"Unknown error" }];
}

static NSError *makeOutOfBoundsError(NSInteger index) {
    NSString *errorText = [NSString stringWithFormat:@"Index %ld is out of bounds", (long)index];
    return [NSError errorWithDomain:kErrorDomainPhotoStore
                               code:ErrorCodesIndexOutOfBounds
                           userInfo:@{ (NSString*)kCFErrorDescriptionKey : errorText }];
}


@interface PhotoStore () {
    
        // Path to the place where the photos are stored.
    NSString *photoFolderPath;
    
        // Path to the properties file for the photos.
    NSString *propertiesFilePath;
    
    NSMutableDictionary *imageProperties;
    
    ThumbnailCache *_thumbnailCache;
    ImageManager *_imageManager;
}

    // Array of thumbnail paths, in sorted order. Guaranteed to be consistent through the lifetime of the program.
-(NSArray*) thumbnailPaths;

@end

@implementation PhotoStore


-(instancetype)init: (NSError **)errorPtr {
    self = [super init];
    if (self) {

        _thumbnailCache = [[ThumbnailCache alloc] init];
        _imageManager = [[ImageManager alloc] init];
        
        if (![self setup:errorPtr]) {
            return nil;
        }
    }
    return self;
}

- (instancetype)init {
    self = [self init:nil];
    NSAssert(NO, @"Don't use [init], use [init:] instead.");
    return self;
}

-(CGSize) thumbnailSize {
    return _thumbnailCache.thumbnailSize;
}

-(BOOL) setup: (NSError **)errorPtr {
    propertiesFilePath = propertiesFile();
    photoFolderPath    = photoFolder(errorPtr);
    if(! photoFolderPath) {
        return NO;
    }
    return [self loadProperties:errorPtr];
}

-(BOOL) saveProperties: (NSError **)errorPtr {
        // Make a copy of the properties that doesn't contain the thumbnails.
    NSMutableDictionary *propsToSave = [NSMutableDictionary dictionaryWithCapacity:imageProperties.count];
    for(NSString *filePath in imageProperties) {
        NSMutableDictionary *newProps = [imageProperties[filePath] mutableCopy];
        [newProps removeObjectForKey:kImagePropertyThumbnail];
        propsToSave[filePath] = newProps;
    }
        // Add a version number in case we change the format.
    propsToSave[kVersion] = @1.0;
    
        // and write it to the properties file.
    BOOL ok = [propsToSave writeToFile:propertiesFilePath atomically:YES];
    if (!ok && errorPtr) {
        *errorPtr = [NSError errorWithDomain:kErrorDomainPhotoStore
                                        code:ErrorCodesUnknownError
                                    userInfo:@{ NSLocalizedDescriptionKey : @"Error saving the image properties." }];
    }
    return ok;
}


-(BOOL) addImage: (UIImage *)image
       dateTaken: (NSDate *)dateTaken
           error: (NSError **)errorPtr {
    NSData *fileData = UIImageJPEGRepresentation(image, 1.0);
    NSString *filePath = getUniqueFilename(photoFolderPath);
    NSError *error;
    BOOL written = [fileData writeToFile:filePath options:NSDataWritingAtomic error:&error];
    if(written) {
        imageProperties[filePath] = [NSMutableDictionary dictionaryWithObject:dateTaken forKey:kImagePropertyDateTaken];
        [_thumbnailCache addThumbnailForImage:image forKey:filePath];
        return nil;
    }
    return error ? error : makeUnknownError();
}

-(BOOL) replaceImageAtIndex: (NSUInteger)index
                  withImage: (UIImage *)newImage
                      error: (NSError **)errorPtr {
    NSString *filePath = filePathForIndex(index, [self thumbnailPaths]);
    if(! filePath)
        return makeOutOfBoundsError(index);

    NSError *error;
    NSData *fileData = UIImageJPEGRepresentation(newImage, 1.0);
    if(! [fileData writeToFile:filePath options:NSDataWritingAtomic error:&error])
        return error;
    
        // Update the thumbnail to show the new image.
    [_thumbnailCache addThumbnailForImage:newImage forKey:filePath];
    return nil;
}

-(BOOL) deleteImagesAtIndexPaths: (NSArray*)indexPaths
                           error: (NSError **)errorPtr {
    NSArray *storedFilenames = [self thumbnailPaths];
    NSArray *paths = [indexPaths transformedArrayUsingBlock:^id(NSIndexPath *path) { return storedFilenames[path.item]; }];
    for (NSString *filePath in paths) {
        NSError *error;
        if(! [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error])
            return error ? error : makeUnknownError();   // A delete failed. Return the error.
        [imageProperties removeObjectForKey:filePath];  // removes all the properties including the thumbnail.
    }
    return nil; // Everything successful.
}

-(BOOL) copyImageToCameraRoll: (NSUInteger)index
                        error: (NSError **)errorPtr {
    NSError *error;
    UIImage *image = [self imageAtIndex:index error:&error];
    if (image) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        return nil; // success
    }
    return error ? error : makeUnknownError();
};




-(NSUInteger) count {
    NSAssert(imageProperties, @"imageProperties not created.");
    return imageProperties ? imageProperties.count : 0;
}





- (NSString *) description {
    NSString *superDescription = [super description];
    NSString *desc = [NSString stringWithFormat:@"%@ <%lu images loaded>", superDescription, (unsigned long)self.count];
    return desc;
}


-(UIImage *) imageAtIndex: (NSUInteger)index
                    error: (NSError**)errorPtr {
    NSString *path = filePathForIndex(index, [self thumbnailPaths]);
    if(! path) {
        *errorPtr = makeOutOfBoundsError(index);
        return nil;
    }
    UIImage *image = [ImageManager imageFromFile:path error:errorPtr];
    return image;
}


-(UIImage *) thumbnailAtIndex: (NSUInteger)index
                        error: (NSError **)errorPtr {
    
    NSString *path = filePathForIndex(index, [self thumbnailPaths]);
    return [_thumbnailCache thumbnailForKey:path error:errorPtr];
}

#pragma mark - Private methods

-(NSArray *) thumbnailPaths {
        // Note: Candidate for cacheing if speed becomes a problem.
    NSAssert(imageProperties, @"imageProperties hasn't been created.");
    return [imageProperties.allKeys sortedArrayUsingSelector:@selector(compare:)];
}



static NSString *filePathForIndex(NSUInteger index, NSArray *storedFilenames) {
    if(storedFilenames.count <= index)
        [NSException raise:NSRangeException format:@"object requested at index %lu, but there were only %lu images available.",
         (unsigned long)index, (unsigned long)storedFilenames.count];
    return storedFilenames[index];
}


static NSMutableDictionary *loadImageProperties(NSString *propertiesFilePath) {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithContentsOfFile:propertiesFilePath];
        // If the dict exists, check if the version ID is valid.
    if (dictionary) {
        NSCAssert( [dictionary[kVersion] isEqual:@1.0], @"Invalid data version %@", dictionary[kVersion]);
            // Remove the version once the file has passed the check.
            // If we use a later version then I may have to massage data here (i.e. for backward compatibility).
        [dictionary removeObjectForKey:kVersion];
        return dictionary;
    }
    return [NSMutableDictionary dictionary];    // First initialisation. Return an empty dictionary.
}

    // Return all the filenames in the image directory.
static NSSet *loadImageFilenames(NSString *photoFolderPath, NSError **errorPtr) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *fileNames = [fileManager contentsOfDirectoryAtPath:photoFolderPath error:errorPtr];
    if(!fileNames) {
        return nil;
    }
    return [NSSet setWithArray:[fileNames transformedArrayUsingBlock:^NSString *(NSString *object) {
        return [photoFolderPath stringByAppendingPathComponent:object];
    }]];
}

-(BOOL) loadProperties: (NSError**)errorPtr {
        // Load the image properties and then compare them to the actual images, adding or removing entries until they match.
    NSMutableDictionary *allProperties = loadImageProperties(propertiesFilePath);
    if (!allProperties) {
        NSLog(@"Error loading image properties.");
        return NO;
    }
    NSSet *propertyFilenames = [NSSet setWithArray:allProperties.allKeys];
    NSSet *filesystemFilenames = loadImageFilenames(photoFolderPath, errorPtr);
    if (!filesystemFilenames) {
        return NO;
    }
    
        // Remove any entries in propertyFilenames not in filesystemFilenames.
    NSSet *filesToRemove = [propertyFilenames objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        return ![filesystemFilenames containsObject:obj];
    }];
    for (NSString *file in filesToRemove) {
        [allProperties removeObjectForKey:file];
    }
        // Add any entries in filesystemFilenames not in propertyFilenames
    NSSet *filesToAdd = [filesystemFilenames objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        return ![propertyFilenames containsObject:obj];
    }];
    for (NSString *file in filesToAdd) {
        allProperties[file] = [NSMutableDictionary dictionary];
    }
    imageProperties = allProperties;
    return YES;
}



static NSString *photoFolder(NSError **errorPtr) {
    NSArray *folders = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *photoDir = [folders[0] stringByAppendingPathComponent:@"Pictures"];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory = NO, fileExists = [fileManager fileExistsAtPath:photoDir isDirectory:&isDirectory];
    if(fileExists && isDirectory) {
        return photoDir;
    }
        // If the directory doesn't exist, then let the file manager try and create it.
    return [fileManager createDirectoryAtPath:photoDir withIntermediateDirectories:NO attributes:nil error:errorPtr]
        ? photoDir : nil;
}

static NSString *propertiesFile() {
    NSArray *folders = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *propertiesPath = [folders[0] stringByAppendingPathComponent:@"Properties"];
    return propertiesPath;
}

static BOOL fileExists(NSString *fullPath) {
    return [[NSFileManager defaultManager] fileExistsAtPath:fullPath];
}

        // Create a CF GUID, then turn it into a string, which we will return.
        // Add the object into the backing store using this key.
static NSString *getUniqueFilename(NSString *photoDir) {
    CFUUIDRef newUID = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef newUIDString = CFUUIDCreateString(kCFAllocatorDefault, newUID);
    
        // The __bridge in this cast means ARC won't do any allocing or releasing of the string produced by the cast.
        // So I can only use it before CFRelease() is called on it.  StringByAppendingPathComponent makes a new string based on it.
        // I.e. I can only use it in this function (or pass it to some other object which will retain it)
    NSString *filePath = [[photoDir
                           stringByAppendingPathComponent:(__bridge NSString*)newUIDString]
                          stringByAppendingString:@".jpg"];
    CFRelease(newUIDString);
    CFRelease(newUID);
    
    assert(! fileExists(filePath)); // Name should be unique so no photo should exist yet.
    return filePath;
}

@end


