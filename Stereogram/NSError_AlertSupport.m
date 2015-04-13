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

-(void) showAlertWithTitle: (NSString *)title
      parentViewController: (UIViewController *)parentViewController {
    NSString *errorText = self.helpAnchor ? self.helpAnchor
    : self.localizedFailureReason ? self.localizedFailureReason
    : self.localizedDescription;
    
        // UIAlertController only valid after iOS 8.
//    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
//                                                                             message:errorText
//                                                                      preferredStyle:UIAlertControllerStyleAlert];
//
//    [parentViewController presentViewController:alertController
//                                       animated:YES
//                                     completion:nil];

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:errorText
                                                       delegate:nil
                                              cancelButtonTitle:@"Close"
                                              otherButtonTitles:nil];
    [alertView show];
}

@end
