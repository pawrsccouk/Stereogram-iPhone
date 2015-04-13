//
//  ErrorData.h
//  Stereogram
//
//  Created by Patrick Wallace on 10/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

#import <Foundation/Foundation.h>

    // Error domain and codes for the Photo Store.

static NSString * const kPWErrorDomainPhotoStore;


enum PWErrorCodes {
    kPWErrorCodesUnknownError             =   1,
    kPWErrorCodesCouldntCreateSharedStore = 100,
    kPWErrorCodesCouldntLoadImageProperties    ,
    kPWErrorCodesIndexOutOfBounds
};

    // Keys of image properties.

extern NSString *const kPWImagePropertyOrientation     // Portrait or Landscape.
, *const kPWImagePropertyThumbnail       // Image thumbnail.
, *const kPWImagePropertyDateTaken       // Date original photo was taken.
, *const kPWImagePropertyViewMode        // Crosseyed, Walleyed, Red/Green, Random-dot
    // Keys for loading and saving.
, *const kPWVersion;         // Save file version.
