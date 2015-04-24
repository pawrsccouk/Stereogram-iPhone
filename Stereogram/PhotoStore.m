    ///
    ///  PhotoStore.m
    ///  Stereogram
    ///
    ///  Created by Patrick Wallace on 20/01/2013.
    ///  Copyright (c) 2013 Patrick Wallace. All rights reserved.
    ///

#import "PhotoStore.h"
#import "PWFunctional.h"
#import "Stereogram.h"
#import "ErrorData.h"
#import "UIImage+Resize.h"

NSString *const PhotoStoreErrorDomain = @"PhotoStore";

    /*! PhotoStore private extensions. */
@interface PhotoStore () {
    
        /*! Path to the place where the photos are stored. */
    NSURL *_photoFolderURL;
    
        /*! Array of stereogram objects currently stored. */
    NSMutableArray *_stereograms;
}

@end

    /*! PhotoStore implementation */
@implementation PhotoStore

-(instancetype) init: (NSError **)errorPtr {
    self = [super init];
    if (self) {
        if (![self setup:errorPtr]) {
            return nil;
        }
    }
    return self;
}

-(instancetype) init {
    self = [self init:nil];
    NSAssert(NO, @"Don't use [init], use [init:] instead.");
    return self;
}


-(BOOL) setup: (NSError **)errorPtr {
    _photoFolderURL = photoFolderURL(errorPtr);
    if (!_photoFolderURL) {
        return NO;
    }
    _stereograms = [Stereogram allStereogramsUnderURL:_photoFolderURL error:errorPtr].mutableCopy;
    return _stereograms;
}

-(void) addStereogram: (Stereogram *)stereogram {
    if (![_stereograms containsObject:stereogram]) {
        [_stereograms addObject:stereogram];
    }
}


-(Stereogram *) createStereogramFromLeftImage: (UIImage *)leftImage
                                   rightImage: (UIImage *)rightImage
                                        error: (NSError **)errorPtr {
    UIImage *scaledLeft  = [leftImage  resizedImage:CGSizeMake(leftImage.size.width / 2.0, leftImage.size.height / 2.0)
                               interpolationQuality:kCGInterpolationHigh];
    UIImage *scaledRight = [rightImage resizedImage:CGSizeMake(rightImage.size.width / 2.0, rightImage.size.height / 2.0)
                               interpolationQuality:kCGInterpolationHigh];
    
    Stereogram *newStereogram = [Stereogram stereogramWithDirectoryURL:_photoFolderURL
                                                             leftImage:scaledLeft
                                                            rightImage:scaledRight
                                                                 error:errorPtr];
    if (!newStereogram) {
        return nil;
    }
    [self addStereogram:newStereogram];
    return newStereogram;
}

-(BOOL) replaceStereogramAtIndex: (NSUInteger)index
                  withStereogram: (Stereogram *)newStereogram
                           error: (NSError **)errorPtr {
    Stereogram *stereogramToGo = _stereograms[index];
    if (![newStereogram isEqual:stereogramToGo]) {
        if (![stereogramToGo deleteFromDisk:errorPtr]) {
            return NO; // Failed.
        }
        _stereograms[index] = newStereogram;
    }
    return YES;
}

-(BOOL)deleteStereogram:(Stereogram *)stereogram
                  error:(NSError **)errorPtr {
    if (![stereogram deleteFromDisk:errorPtr]) {
        return NO;
    }
    [_stereograms removeObject:stereogram];
    return YES;
}

-(BOOL) deleteStereogramsAtIndexPaths: (NSArray *)indexPaths
                                error: (NSError **)errorPtr {
        // Make a separate array of stereograms to delete so we don't change the array while traversing it.
    NSArray *stereogramsToDelete = [indexPaths transformedArrayUsingBlock:^Stereogram *(NSIndexPath *object) {
        return _stereograms[object.item];
    }];
    for (Stereogram *stereogram in stereogramsToDelete) {
        if (![self deleteStereogram:stereogram
                              error:errorPtr]) {
            return NO;
        }
    }
    return YES; // All the stereograms were deleted.
 }


-(BOOL) copyStereogramToCameraRoll: (NSUInteger)index
                             error: (NSError **)errorPtr {
    Stereogram *stereogram = _stereograms[index];
    UIImage *fullImage = [stereogram stereogramImage:errorPtr];
    if (!fullImage) {
        return NO;
    }
    UIImageWriteToSavedPhotosAlbum(fullImage, nil, nil, nil);
    return YES; // success
};




-(NSUInteger) count {
    return _stereograms.count;
}


- (NSString *) description {
    NSString *superDescription = [super description];
    NSString *desc = [NSString stringWithFormat:@"%@ <%lu images loaded>", superDescription, (unsigned long)self.count];
    return desc;
}


-(Stereogram *) stereogramAtIndex: (NSUInteger)index {
    return _stereograms[index];
}

static NSURL *photoFolderURL(NSError **errorPtr) {
    
    NSArray *folders = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSURL *baseURL = [NSURL fileURLWithPath:folders[0] isDirectory:YES];
    NSURL *photoDir = [baseURL URLByAppendingPathComponent:@"Pictures" isDirectory:YES];
    if (!photoDir) {
        if (errorPtr) {
            *errorPtr = [NSError errorWithDomain:kErrorDomainPhotoStore
                                            code:ErrorCode_CouldntCreateSharedStore
                                        userInfo:@{NSLocalizedDescriptionKey : @"Couldn't locate directory for storing images."}];
        }
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory = NO, fileExists = [fileManager fileExistsAtPath:photoDir.path
                                                          isDirectory:&isDirectory];
    if(fileExists && isDirectory) {
        return photoDir;
    }
        // If the directory doesn't exist, then let the file manager try and create it.
    return [fileManager createDirectoryAtURL:photoDir
                 withIntermediateDirectories:NO
                                  attributes:nil
                                       error:errorPtr]
    ? photoDir : nil;
}


@end


