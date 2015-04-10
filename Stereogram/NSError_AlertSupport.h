//
//  NSError_AlertSupport.h
//  Stereogram
//
//  Created by Patrick Wallace on 21/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSError (AlertSupport)

    /// Shows the error text in an alert window, with a "Close" button.
-(void) showAlertWithTitle: (NSString*)title;

@end
