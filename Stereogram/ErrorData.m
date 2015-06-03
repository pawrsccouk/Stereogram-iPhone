//
//  ErrorData.m
//  Stereogram
//
//  Created by Patrick Wallace on 10/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

#import "ErrorData.h"

NSString * const kErrorDomainPhotoStore = @"PhotoStore";

    // Keys for the image properties.
NSString * const kImagePropertyOrientation   = @"Orientation";     // Portrait or Landscape.
NSString * const kImagePropertyThumbnail     = @"Thumbnail";       // Image thumbnail.
NSString * const kImagePropertyDateTaken     = @"DateTaken";       // Date original photo was taken.
NSString * const kImagePropertyViewMode      = @"ViewMode";        // Crosseyed, Walleyed, Red/Green, Random-dot
    // Keys for loading and saving.
NSString * const kVersion                    = @"Version";         // Save file version.
