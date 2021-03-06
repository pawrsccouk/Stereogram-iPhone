//
//  UIImage+Export.h
//  Stereogram
//
//  Created by Patrick Wallace on 23/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

@import UIKit;

/*!
 * Extension to get GIF and JPEG data out of an image.
 */
@interface UIImage (Export)



/*!
 * Return this image as an NSData object representing a GIF.
 */

@property (nonatomic, readonly) NSData *asGIFData;




/*!
 * Return this image as an NSData object representing a JPEG.
 */

@property (nonatomic, readonly) NSData *asJPEGData;

@end
