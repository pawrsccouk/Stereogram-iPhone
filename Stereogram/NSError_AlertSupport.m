//
//  NSError_AlertSupport.h
//  Stereogram
//
//  Created by Patrick Wallace on 21/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIKit/UIKit.h"

@implementation NSError (AlertSupport)

    // Shows the error text in an alert window, with a "Close" button.
-(void)showAlertWithTitle:(NSString*)title
{
    NSString *errorText = self.helpAnchor ? self.helpAnchor
                                          : self.localizedFailureReason ? self.localizedFailureReason
                                                                        : self.localizedDescription;
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:errorText
                                                       delegate:nil
                                              cancelButtonTitle:@"Close"
                                              otherButtonTitles:nil];
    [alertView show];
}

@end
