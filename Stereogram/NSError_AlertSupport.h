/*!
 * @file NSError_AlertSupport.h
 * @abstract An extension to NSError to allow it to display the error as an alert.
 * @author Patrick Wallace on 21/01/2013.
 * @copyright (c) 2013 Patrick Wallace. All rights reserved.
 */

#import <Foundation/Foundation.h>

/*! Extension to NSError to display an alert view containing the error details.
 */
@interface NSError (AlertSupport)

/*! Shows the error text in an alert window above the parent view controller.
 */
-(void) showAlertWithTitle: (NSString*)title
      parentViewController: (UIViewController *)parentViewController;

@end
