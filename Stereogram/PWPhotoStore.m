//
//  PWPhotoStore.m
//  Stereogram
//
//  Created by Patrick Wallace on 20/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import "PWPhotoStore.h"
#import "PWFunctional.h"
#import "UIImage+Resize.h"

    // Keys for the image properties.
static NSString * const kPWImagePropertyOrientation   = @"Orientation",     // Portrait or Landscape.
                * const kPWImagePropertyThumbnail     = @"Thumbnail",       // Image thumbnail.
                * const kPWImagePropertyDateTaken     = @"DateTaken",       // Date original photo was taken.
                * const kPWImagePropertyViewMode      = @"ViewMode",        // Crosseyed, Walleyed, Red/Green, Random-dot
    // Keys for loading and saving.
                * const kPWVersion                    = @"Version";         // Save file version.

    // Viewing method for the image.
enum ViewingMethod { viewingMethodCrosseye, viewingMethodWalleye };

@interface PWPhotoStore ()
{
        // Key is image file path, Value is a dictionary of standard properties for the image.
    NSMutableDictionary *imageProperties;
    
        // Path to the place where the photos are stored.
    NSString *photoFolderPath;
    
        // Path to the properties file for the photos.
    NSString *propertiesFilePath;
}

    // Array of thumbnail paths, in sorted order. Guaranteed to be consistent through the lifetime of the program.
-(NSArray*) thumbnailPaths;

@end

@implementation PWPhotoStore


+(NSError*)setupStore
{
    PWPhotoStore *store = [self sharedStore];
    return store ? [store setup]
                 : [NSError errorWithDomain:kPWErrorDomainPhotoStore
                                       code:kPWErrorCodesCouldntCreateSharedStore
                                   userInfo:@{ (NSString*)kCFErrorDescriptionKey : @"Error creating shared photo store" }];
}

+(PWPhotoStore *)sharedStore
{
        // Allocate memory for the store the first time it is used. Otherwise, just pass the shared pointer back.
    static PWPhotoStore *singleStore = nil;
    if(!singleStore)
        singleStore = [[super allocWithZone:nil] init];

    return singleStore;
}

-(id)init
{
    self = [super init];
    if(self) {

            // We want the clearCache method to be called when memory becomes low.
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self
               selector:@selector(clearCache:)
                   name:UIApplicationDidReceiveMemoryWarningNotification
                 object:nil];
    }
    return self;
}

-(NSError *)setup
{
    NSError *error ;
    propertiesFilePath = propertiesFile();
    photoFolderPath    = photoFolder(&error);
    if(! photoFolderPath) return error;
    
    return [self loadProperties];
}

-(NSError *)saveProperties
{
        // Make a copy of the properties that doesn't contain the thumbnails.
    NSMutableDictionary *propsToSave = [NSMutableDictionary dictionaryWithCapacity:imageProperties.count];
    for(NSString *filePath in imageProperties) {
        NSMutableDictionary *newProps = [imageProperties[filePath] mutableCopy];
        [newProps removeObjectForKey:kPWImagePropertyThumbnail];
        propsToSave[filePath] = newProps;
    }
        // Add a version number in case we change the format.
    propsToSave[kPWVersion] = @1.0;
    
        // and write it to the properties file.
    BOOL ok = [propsToSave writeToFile:propertiesFilePath atomically:YES];
    return ok ? nil : [NSError errorWithDomain:kPWErrorDomainPhotoStore
                                          code:kPWErrorCodesUnknownError
                                      userInfo:@{ (NSString*)kCFErrorDescriptionKey : @"Error saving the image properties." }];
}

-(UIImage *)imageAtIndex:(NSUInteger)index error:(NSError**)error
{
    NSString *path = filePathForIndex(index, [self thumbnailPaths]);
    if(! path) {
        *error = makeOutOfBoundsError(index);
        return nil;
    }
    UIImage *image = [self imageFromFile:path error:error];
//    if(image)
//        [self addThumbnailToCache:image forKey:path];
    return image;
}


-(UIImage *)thumbnailAtIndex:(NSUInteger)index error:(NSError *__autoreleasing *)error
{
    NSString *path = filePathForIndex(index, [self thumbnailPaths]);
    UIImage  *thumb = imageProperties[path][kPWImagePropertyThumbnail];
    if(thumb) return thumb;
    
    UIImage *image = [self imageFromFile:path error:error];
    return image ? [self addThumbnailToCache:image forKey:path] : nil;
}

-(NSError *)addImage:(UIImage *)image dateTaken:(NSDate *)dateTaken
{
    NSData *fileData = UIImageJPEGRepresentation(image, 1.0);
    NSString *filePath = getUniqueFilename(photoFolderPath);
    NSError *error;
    BOOL written = [fileData writeToFile:filePath options:NSDataWritingAtomic error:&error];
    if(written) {
        imageProperties[filePath] = [NSMutableDictionary dictionaryWithObject:dateTaken forKey:kPWImagePropertyDateTaken];
        [self addThumbnailToCache:image forKey:filePath];
        return nil;
    }
    return error ? error : makeUnknownError();
}

-(NSError *)replaceImageAtIndex:(NSUInteger)index withImage:(UIImage *)newImage
{
    NSString *filePath = filePathForIndex(index, [self thumbnailPaths]);
    if(! filePath)
        return makeOutOfBoundsError(index);

    NSError *error;
    NSData *fileData = UIImageJPEGRepresentation(newImage, 1.0);
    if(! [fileData writeToFile:filePath options:NSDataWritingAtomic error:&error])
        return error;
    
        // Update the thumbnail to show the new image.
    [self addThumbnailToCache:newImage forKey:filePath];
    return nil;
}

-(NSError *)deleteImagesAtIndexPaths:(NSArray*)indexPaths
{
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

-(NSError*)copyImageToCameraRoll:(NSUInteger)index
{
    NSError *error;
    UIImage *image = [self imageAtIndex:index error:&error];
    if (image) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        return nil; // success
    }
    return error ? error : makeUnknownError();
};

   // Function to return half an image.
enum WhichHalf { RightHalf, LeftHalf };
static UIImage *getHalfOfImage(UIImage * image, enum WhichHalf whichHalf)
{
    CGRect rectToKeep = (whichHalf == LeftHalf) ? CGRectMake(0, 0, image.size.width / 2.0, image.size.height)
                                                : CGRectMake(image.size.width / 2.0, 0, image.size.width / 2.0, image.size.height );
    
    CGImageRef imgPartRef = CGImageCreateWithImageInRect(image.CGImage, rectToKeep);
    UIImage *imgPart = [UIImage imageWithCGImage:imgPartRef];
    CGImageRelease(imgPartRef);
    return imgPart;
};

-(NSError *)changeViewingMethod:(NSUInteger)index
{
    NSError *error;
    UIImage *image = [self imageAtIndex:index error:&error];
    if(image) {
        UIImage *swappedImage = [self makeStereogramWith:getHalfOfImage(image, RightHalf)
                                                     and:getHalfOfImage(image, LeftHalf)];
        NSAssert(CGSizeEqualToSize(swappedImage.size, image.size), @"Error swapping the image. Size (%f,%f) doesn't match original (%f, %f)",
                 swappedImage.size.width, swappedImage.size.height, image.size.width, image.size.height);

        [self replaceImageAtIndex:index withImage:swappedImage];
        return nil; // Success
    }
        // If we reach here something went wrong. Return what.
    return error ? error : makeUnknownError();
}

    // Called by the notification centre when it receives a low-memory warning notification.
-(void)clearCache:(NSNotification*)notification
{
        // Remove all the thumbnails.
    for(NSString *key in imageProperties) {
        [imageProperties[key] removeObjectForKey:kPWImagePropertyThumbnail];
    }
}

-(NSUInteger)count
{
    NSAssert(imageProperties, @"imageProperties not created.");
    return imageProperties ? imageProperties.count : 0;
}


-(NSUInteger)thumbnailSize
{
    return 100;
}

-(UIImage *)makeStereogramWith:(UIImage *)leftPhoto and:(UIImage *)rightPhoto
{
    NSAssert(leftPhoto.scale == rightPhoto.scale, @"Image scales %f and %f need to be the same.", leftPhoto.scale, rightPhoto.scale);
    CGSize stereogramSize = CGSizeMake(leftPhoto.size.width + rightPhoto.size.width, MAX(leftPhoto.size.height, rightPhoto.size.height));
    UIImage *stereogram = nil;
    UIGraphicsBeginImageContextWithOptions(stereogramSize, NO, leftPhoto.scale);
    @try {
        [leftPhoto drawAtPoint:CGPointMake(0, 0)];
        [rightPhoto drawAtPoint:CGPointMake(leftPhoto.size.width, 0)];
        stereogram = UIGraphicsGetImageFromCurrentImageContext();
    }
    @finally {
        UIGraphicsEndImageContext();
    }
    NSAssert(stereogram, @"Stereogram not created.");
    return stereogram;
}


#pragma mark - Private methods

-(NSArray *)thumbnailPaths
{
        // Note: Candidate for cacheing if speed becomes a problem.
    NSAssert(imageProperties, @"imageProperties hasn't been created.");
    return [imageProperties.allKeys sortedArrayUsingSelector:@selector(compare:)];
}

-(UIImage*) imageFromFile:(NSString*)filePath error:(NSError**)error
{
    NSAssert(filePath && [[NSFileManager defaultManager] fileExistsAtPath:filePath], @"filePath [%@] does not point to a file.", filePath);
    return [UIImage imageWithData:[NSData dataWithContentsOfFile:filePath options:0 error:error]];
}



static NSString *filePathForIndex(NSUInteger index, NSArray *storedFilenames)
{
    if(storedFilenames.count <= index)
        [NSException raise:NSRangeException format:@"object requested at index %d, but there were only %d images available.",
         index, storedFilenames.count];
    return storedFilenames[index];
}


static NSError *makeUnknownError()
{
    return [NSError errorWithDomain:kPWErrorDomainPhotoStore
                               code:kPWErrorCodesUnknownError
                           userInfo:@{ (NSString*)kCFErrorDescriptionKey : @"Unknown error" }];
}

static NSError *makeOutOfBoundsError(NSInteger index)
{
    NSString *errorText = [NSString stringWithFormat:@"Index %d is out of bounds", index];
    return [NSError errorWithDomain:kPWErrorDomainPhotoStore
                               code:kPWErrorCodesIndexOutOfBounds
                           userInfo:@{ (NSString*)kCFErrorDescriptionKey : errorText }];
}

static NSMutableDictionary *loadImageProperties(NSString *propertiesFilePath)
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithContentsOfFile:propertiesFilePath];
        // If the dict exists, check if the version ID is valid.
    if(dictionary) {
        NSCAssert( [dictionary[kPWVersion] isEqual:@1.0], @"Invalid data version %@", dictionary[kPWVersion]);
            // Remove the version once the file has passed the check.
            // If we use a later version then I may have to massage data here (i.e. for backward compatibility).
        [dictionary removeObjectForKey:kPWVersion];
        return dictionary;
    }
    return [NSMutableDictionary dictionary];    // First initialisation. Return an empty dictionary.
}

    // Return all the filenames in the image directory.
static NSSet *loadImageFilenames(NSString *photoFolderPath, NSError **error)
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *fileNames = [fileManager contentsOfDirectoryAtPath:photoFolderPath error:error];
    if(!fileNames) return nil;
    
    return [NSSet setWithArray:[fileNames transformedArrayUsingBlock:^NSString *(NSString *object) {
        return [photoFolderPath stringByAppendingPathComponent:object];
    }]];
}

-(NSError*)loadProperties
{
        // Load the image properties and then compare them to the actual images, adding or removing entries until they match.
    NSError *error;
    NSMutableDictionary *allProperties = loadImageProperties(propertiesFilePath);
    if(error) return error;
    
    NSSet *propertyFilenames = [NSSet setWithArray:allProperties.allKeys];
    NSSet *filesystemFilenames = loadImageFilenames(photoFolderPath, &error);
    if(error) return error;
    
        // Remove any entries in propertyFilenames not in filesystemFilenames.
    NSSet *filesToRemove = [propertyFilenames objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        return ![filesystemFilenames containsObject:obj];
    }];
    for(NSString *file in filesToRemove)
        [allProperties removeObjectForKey:file];
    
        // Add any entries in filesystemFilenames not in propertyFilenames
    NSSet *filesToAdd = [filesystemFilenames objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        return ![propertyFilenames containsObject:obj];
    }];
    for(NSString *file in filesToAdd)
        allProperties[file] = [NSMutableDictionary dictionary];
    
    imageProperties = allProperties;
    return nil;
}



+(id)allocWithZone:(NSZone *)zone
{
    [NSException raise:@"Logic exception" format:@"PWPhotoStore is a singleton. Use the sharedStore method instead of allocing your own copy."];
    return nil;
}

-(UIImage *)addThumbnailToCache:(UIImage *)image forKey:(id)key
{
        // The thumbnail should be of one half of the image, so the user can recognise it.
    UIImage *leftHalf = getHalfOfImage(image, LeftHalf);
    UIImage *thumbnail = [leftHalf thumbnailImage:[self thumbnailSize] transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationLow];
    NSMutableDictionary *properties = imageProperties[key];
    if(! properties) {
        properties = [NSMutableDictionary dictionary];
        imageProperties[key] = properties;
    }
    properties[kPWImagePropertyThumbnail] = thumbnail;
    return thumbnail;
}

static NSString *photoFolder(NSError **error)
{
    NSArray *folders = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *photoDir = [folders[0] stringByAppendingPathComponent:@"Pictures"];
        
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory = NO, fileExists = [fileManager fileExistsAtPath:photoDir isDirectory:&isDirectory];
    if(fileExists && isDirectory) return photoDir;
    
        // If the directory doesn't exist, then let the file manager try and create it.
    return [fileManager createDirectoryAtPath:photoDir withIntermediateDirectories:NO attributes:nil error:error]
        ? photoDir : nil;
}

static NSString *propertiesFile()
{
    NSArray *folders = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *propertiesPath = [folders[0] stringByAppendingPathComponent:@"Properties"];
    return propertiesPath;
}

static BOOL fileExists(NSString *fullPath)
{
    return [[NSFileManager defaultManager] fileExistsAtPath:fullPath];
}

        // Create a CF GUID, then turn it into a string, which we will return.
        // Add the object into the backing store using this key.
static NSString *getUniqueFilename(NSString *photoDir)
{
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


