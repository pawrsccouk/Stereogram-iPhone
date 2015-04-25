//
//  UIImage+Export.m
//  Stereogram
//
//  Created by Patrick Wallace on 23/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

@import ImageIO;
@import MobileCoreServices.UTCoreTypes;
#import "UIImage+Export.h"

@implementation UIImage (Export)


-(NSData *) GIFData {
    CFMutableDataRef mutableData = CFDataCreateMutable(kCFAllocatorDefault, 0);
    NSUInteger numFrames = self.images ? self.images.count : 1;
    CGImageDestinationRef cgImage = CGImageDestinationCreateWithData(mutableData, kUTTypeGIF, numFrames, nil);
    if (self.images) {
        for (UIImage *frame in self.images) {
            CGImageDestinationAddImage(cgImage, frame.CGImage, nil);
        }
    } else { // Only one image.
        CGImageDestinationAddImage(cgImage, self.CGImage, nil);
    }
    CGImageDestinationFinalize(cgImage);
    return CFBridgingRelease(mutableData);
}

-(NSData *) JPEGData {
    return UIImageJPEGRepresentation(self, 1.0);
}

@end
