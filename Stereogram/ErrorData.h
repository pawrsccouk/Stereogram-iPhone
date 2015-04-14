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


enum ErrorCodes {
    ErrorCodesUnknownError             =   1,
    ErrorCodesCouldntCreateSharedStore = 100,
    ErrorCodesCouldntLoadImageProperties    ,
    ErrorCodesIndexOutOfBounds
};

    // Keys of image properties.

extern NSString *const kImagePropertyOrientation;     // Portrait or Landscape.
extern NSString *const kImagePropertyThumbnail;       // Image thumbnail.
extern NSString *const kImagePropertyDateTaken;       // Date original photo was taken.
extern NSString *const kImagePropertyViewMode;        // Crosseyed, Walleyed, Red/Green, Random-dot
    // Keys for loading and saving.
extern NSString *const kVersion;         // Save file version.
