//
//  ErrorData.h
//  Stereogram
//
//  Created by Patrick Wallace on 10/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

#import <Foundation/Foundation.h>

    // Error domain and codes for the Photo Store.

static NSString * const kErrorDomainPhotoStore;

typedef NS_ENUM(NSInteger, ErrorCodes) {
    ErrorCode_UnknownError             =   1,
    ErrorCode_CouldntCreateSharedStore = 100,
    ErrorCode_CouldntLoadImageProperties    ,
    ErrorCode_InvalidFileFormat             ,
    ErrorCode_IndexOutOfBounds              ,
    ErrorCode_NotImplemented                ,
};

    // Keys of image properties.

extern NSString *const kImagePropertyOrientation;     // Portrait or Landscape.
extern NSString *const kImagePropertyThumbnail;       // Image thumbnail.
extern NSString *const kImagePropertyDateTaken;       // Date original photo was taken.
extern NSString *const kImagePropertyViewMode;        // Crosseyed, Walleyed, Red/Green, Random-dot
    // Keys for loading and saving.
extern NSString *const kVersion;         // Save file version.
