//
//  UIImage+Export.h
//  Stereogram
//
//  Created by Patrick Wallace on 23/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIImage (Export)

@property (nonatomic, readonly) NSData *GIFData;
@property (nonatomic, readonly) NSData *JPEGData;

@end
