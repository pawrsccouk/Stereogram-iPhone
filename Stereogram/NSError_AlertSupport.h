/*!
 * @file NSError_AlertSupport.h
 * @abstract An extension to NSError to allow it to display the error as an alert.
 * @author Patrick Wallace on 21/01/2013.
 * @copyright (c) 2013 Patrick Wallace. All rights reserved.
 */

@import Foundation;

    // These are keys into the userInfo dictionary for unknownError NSError objects.
extern NSString * const kLocationKey, *const kCallerKey, *const kTargetKey;


/*!
 * Extension to NSError to display an alert view containing the error details.
 */
@interface NSError (AlertSupport)

/*! 
 * Shows the error text in an alert window above the parent view controller.
 *
 * @param title The title to show above the alert.
 * @param parentViewController The view controller the receiver will obscure. Not currently used.
 */
-(void) showAlertWithTitle: (NSString*)title
      parentViewController: (UIViewController *)parentViewController;

/*! 
 * Returns a default error for use when something went wrong but didn't give a reason.
 *
 * @param location The function that failed.
 * @return A default error which includes LOCATION in the error message and userInfo dictionary.
 */
+(NSError *) unknownErrorWithLocation: (NSString *)location;

/*! 
 * Returns a default error for use when something went wrong but didn't give a reason.
 *
 * The general appearance of the error should indicate something like 
 * "Inside "myFunction" there was an error calling "theirFunction".
 *
 * @param caller  The function we were in when the problem occurred (My function).
 * @param target  The object that we called the method on which failed.
 * @param method  The method that failed. Usually an iOS function (a selector to a method on target).
 * @return A default error which includes CALLER, TARGET and METHOD in the error message and userInfo dictionary.
 */
+(NSError *) unknownErrorWithCaller: (NSString *)caller
                             target: (id)target
                             method: (SEL)method;


/*!
 * Returns a default error for use when a parameter is nil and shouldn't be.
 *
 * @param parameter  The name of the parameter that was nil.
 * @return A default error which includes CALLER, TARGET and METHOD in the error message and userInfo dictionary.
 */
+(NSError *) parameterErrorWithNilParameter: (NSString *)parameter;

/*!
 * Returns a default error for use when a parameter has an invalid value.
 *
 * @param parameter    The name of the parameter that was wrong.
 * @param valuePassed  The value of the parameter that was wrong.
 * @return A default error which includes CALLER, TARGET and METHOD in the error message and userInfo dictionary.
 */
+(NSError *) parameterErrorWithParameter: (NSString *)parameter
							 valuePassed: (id)valuePassed;

@end
