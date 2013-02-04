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

@implementation PWPhotoStore

+(BOOL)setupStore:(NSError**)error
{
    PWPhotoStore *store = [self sharedStore];
    if(store)
        if(! [store loadImageFilenames:error] ) return NO;
    return NO;
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

-(NSString *)filePathForIndex:(NSUInteger)index
{
    NSAssert(storedFilenames, @"storedFilenameCache hasn't been created.");
    if(storedFilenames.count <= index)
        [NSException raise:NSRangeException format:@"object requested at index %d, but there were only %d images available.",
                                                   index, storedFilenames.count];
    return storedFilenames[index];
}

-(UIImage*) imageFromFile:(NSString*)filePath error:(NSError**)error
{
    NSAssert(filePath && [[NSFileManager defaultManager] fileExistsAtPath:filePath], @"filePath [%@] does not point to a file.", filePath);
    return [UIImage imageWithData:[NSData dataWithContentsOfFile:filePath options:0 error:error]];
}

-(UIImage *)imageAtIndex:(NSUInteger)index error:(NSError**)error
{
    NSString *path = [self filePathForIndex:index];
    UIImage *image = [self imageFromFile:path error:error];
    if(image)
        [self addThumbnailToCache:image forKey:path];
    return image;
}


-(UIImage *)thumbnailAtIndex:(NSUInteger)index error:(NSError *__autoreleasing *)error
{
    NSString *path = storedFilenames[index];
    UIImage  *thumb = thumbnailCache[path];
    if(thumb) return thumb;
    
    UIImage *image = [self imageFromFile:path error:error];
    return image ? [self addThumbnailToCache:image forKey:path] : nil;
}

-(BOOL)addImage:(UIImage *)image error:(NSError **)error
{
    NSData *fileData = UIImageJPEGRepresentation(image, 1.0);
    NSString *filePath = getUniqueFilename(photoFolderPath);
    BOOL written = [fileData writeToFile:filePath options:NSDataWritingAtomic error:error];
    if(written) {
        [self addThumbnailToCache:image forKey:filePath];
        [storedFilenames addObject:filePath];
    }
    return written;
}

-(BOOL)deleteImagesAtIndexPaths:(NSArray*)indexPaths error:(NSError *__autoreleasing *)error
{
    NSArray *paths = [indexPaths transformedArrayUsingBlock:^id(NSIndexPath *path) { return storedFilenames[path.item]; }];
    for (NSString *filePath in paths) {
        BOOL deleted = [[NSFileManager defaultManager] removeItemAtPath:filePath error:error];
        if(deleted) {
            [self deleteThumbnailFromCache:filePath];    // Keep the cache & filename list up to date.
            [storedFilenames removeObject:filePath];
        } else return NO;   // A delete failed. Return the error.
    }
    return YES; // Everything successful.
}

-(BOOL)copyImageToCameraRoll:(NSUInteger)index error:(NSError**)error
{
    UIImage *image = [self imageAtIndex:index error:error];
    if (image)
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    return (image != nil);
};


    // Called by the notification centre when it receives a low-memory warning notification.
-(void)clearCache:(NSNotification*)notification
{
    thumbnailCache    = nil;
}

-(NSUInteger)count
{
    NSAssert(storedFilenames, @"storedFilenameCache not created.");
    return storedFilenames ? storedFilenames.count : 0;
}


-(NSUInteger)thumbnailSize
{
    return 100;
}

static NSString *stringFromSize(CGSize size) { return [NSString stringWithFormat:@"(%f,%f)", size.width, size.height]; }

-(UIImage *)makeStereogramWith:(UIImage *)firstPhoto and:(UIImage *)secondPhoto
{
    NSAssert(firstPhoto.scale == secondPhoto.scale, @"Image scales %f and %f need to be the same.", firstPhoto.scale, secondPhoto.scale);
    CGSize stereogramSize = CGSizeMake(firstPhoto.size.width + secondPhoto.size.width, MAX(firstPhoto.size.height, secondPhoto.size.height));
    UIImage *stereogram = nil;
    UIGraphicsBeginImageContextWithOptions(stereogramSize, NO, firstPhoto.scale);
    @try {
        [firstPhoto drawAtPoint:CGPointMake(0, 0)];
        [secondPhoto drawAtPoint:CGPointMake(firstPhoto.size.width, 0)];
        stereogram = UIGraphicsGetImageFromCurrentImageContext();
    }
    @finally {
        UIGraphicsEndImageContext();
    }
    NSAssert(stereogram, @"Stereogram not created.");
        // Halve the stereogram size as otherwise these end up way too big, since we've doubled the width of the image.
        // TODO: Make this an option to be checked in the preferences.
    return [stereogram resizedImage:CGSizeMake(stereogram.size.width / 2, stereogram.size.height / 2) interpolationQuality:kCGInterpolationHigh];
}


#pragma mark - Private methods

-(BOOL)loadImageFilenames:(NSError**)error
{    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSError *myError = nil;
    NSArray *fileNames = nil;
    
    if((photoFolderPath = photoFolder(&myError)) != nil)
        fileNames = [fileManager contentsOfDirectoryAtPath:photoFolderPath error:&myError];
    
    if(!fileNames) {
        if(myError) {
            NSLog(@"Error reading the image directory [%@]. Error was %@ (%@)", photoFolderPath, myError, myError.userInfo);
            if(error)
                *error = myError;
        }
        return FALSE;
    }
    storedFilenames = [[fileNames transformedArrayUsingBlock:^id(NSString *object) {
        return [photoFolderPath stringByAppendingPathComponent:object];
    }] mutableCopy];
    return (storedFilenames != nil);
}



+(id)allocWithZone:(NSZone *)zone
{
    [NSException raise:@"Logic exception" format:@"PWPhotoStore is a singleton. Use the sharedStore method instead of allocing your own copy."];
    return nil;
}

-(UIImage *)addThumbnailToCache:(UIImage *)image forKey:(id)key
{
    if(! thumbnailCache)
        thumbnailCache = [NSMutableDictionary dictionary];
    UIImage *thumbnail = [image thumbnailImage:[self thumbnailSize] transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationLow];
    thumbnailCache[key] = thumbnail;
    return thumbnail;
}

-(UIImage *)thumbnailFromCache:(id)key
{
    if(! thumbnailCache)
        thumbnailCache = [NSMutableDictionary dictionary];
    return thumbnailCache[key];
}

-(void)deleteThumbnailFromCache:(id)key
{
    [thumbnailCache removeObjectForKey:key];
}


 static void writeImageToFile(UIImage *image, NSString *path)
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]) {
        NSLog(@"Skipping creating sample data %@ as it exists already", path);
    }
    else {
        BOOL written = [UIImageJPEGRepresentation(image, 1.0) writeToFile:path atomically:YES];
        NSLog(@"Image written to path %@: Success = %@", path, written ? @"YES" : @"NO");
    }
}

//-(void)createSampleData
//{
//    NSAssert(photoFolderPath, @"photoFolderPath should not be nil");
//    NSString *sampleData1Path = [[NSBundle mainBundle] pathForResource:@"Sample Picture 1" ofType:@"jpg"];
//    NSString *sampleData2Path = [[NSBundle mainBundle] pathForResource:@"Sample Picture 2" ofType:@"jpg"];
//    UIImage *sampleImage1 = [UIImage imageWithContentsOfFile:sampleData1Path];
//    if(! sampleImage1) { abort();  }
//    UIImage *sampleImage2 = [UIImage imageWithContentsOfFile:sampleData2Path];
//    if(! sampleImage2) { abort();  }
//    NSString *file1Path = [photoFolderPath stringByAppendingPathComponent:@"Image1"];
//    NSString *file2Path = [photoFolderPath stringByAppendingPathComponent:@"Image2"];
//    NSString *file3Path = [photoFolderPath stringByAppendingPathComponent:@"Image3"];
//    NSString *file4Path = [photoFolderPath stringByAppendingPathComponent:@"Image4"];
//    writeImageToFile(sampleImage1, file1Path);
//    writeImageToFile(sampleImage2, file2Path);
//    writeImageToFile(sampleImage1, file3Path);
//    writeImageToFile(sampleImage2, file4Path);
//}


static BOOL createPhotoFolder(NSString *photoFolder, NSError **error)
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory = NO, fileExists = [fileManager fileExistsAtPath:photoFolder isDirectory:&isDirectory];
    if(fileExists && isDirectory) return YES;
    
        // If the file is not a directory, then let the file manager try and create a dir over it.
        // This will fail and return an appropriate error.
    return [fileManager createDirectoryAtPath:photoFolder withIntermediateDirectories:NO attributes:nil error:error];
}

static NSString *photoFolder(NSError **error)
{
    NSArray *folders = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *photoDir = [folders[0] stringByAppendingPathComponent:@"Pictures"];
    
//    NSLog(@"Using path [%@] for storing photos.", photoDir);
    if(! createPhotoFolder(photoDir, error)) return nil;
    return photoDir;
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
        // So I can only use it before CFRelease() is called on it.
        // I.e. I can only use it in this function (or pass it to some other object which will retain it)
    NSString *filePath = [photoDir stringByAppendingPathComponent:(__bridge NSString*)newUIDString];

    CFRelease(newUIDString);
    CFRelease(newUID);
    
    assert(! fileExists(filePath)); // Name should be unique so no photo should exist yet.
    return filePath;
}

@end


