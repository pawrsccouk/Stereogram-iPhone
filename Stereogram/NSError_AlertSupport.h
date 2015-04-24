/*!
 * @file NSError_AlertSupport.h
 * @abstract An extension to NSError to allow it to display the error as an alert.
 * @author Patrick Wallace on 21/01/2013.
 * @copyright (c) 2013 Patrick Wallace. All rights reserved.
 */

#import <Foundation/Foundation.h>


    // These are keys into the userInfo dictionary for unknownError NSError objects.
extern NSString * const kLocationKey, *const kCallerKey, *const kTargetKey;


/*! Extension to NSError to display an alert view containing the error details.
 */
@interface NSError (AlertSupport)

/*! Shows the error text in an alert window above the parent view controller.
 */
-(void) showAlertWithTitle: (NSString*)title
      parentViewController: (UIViewController *)parentViewController;

/*! Returns a default error for use when something went wrong but didn't give a reason.
 *
 * @param location The function that failed.
 */
+(NSError *) unknownErrorWithLocation: (NSString *)location;

/*! Returns a default error for use when something went wrong but didn't give a reason.
 *
 * The general appearance of the error should indicate something like 
 * "Inside "myFunction" there was an error calling "theirFunction".
 *
 * @param caller  The function we were in when the problem occurred (My function).
 * @param target  The object that we called the method on which failed.
 * @param method  The method that failed. Usually an iOS function (a selector to a method on target).
 */
+(NSError *) unknownErrorWithCaller: (NSString *)caller
                             target: (id)target
                             method: (SEL)method;

@end
