/*!
 * @file PWAlertView.h
 * @author Patrick Wallace on 30/01/2013.
 * @copyright 2013 Patrick Wallace. All rights reserved.
 */

@import Foundation;
@class PWAction;

/*!
 * A variant of NSAlertView which uses blocks instead of delegates.
 *
 * Internally calls UIAlertView with the delegate set to self, and handles the button text.
 * Similar to UIAlertController which we can switch to if we only want to target iOS8.
 */

@interface PWAlertView : NSObject <UIAlertViewDelegate>

#pragma mark Constructors

/*! 
 * Class method to return a new Alert View.
 *
 * @param title          The title to display on the alert.
 * @param message        The main message of the alert.
 * @param preferredStyle This is not currently used.
 */

+(instancetype) alertViewWithTitle: (NSString*)title
                           message: (NSString*)message
                    preferredStyle: (UIAlertControllerStyle)preferredStyle;



/*!
 * Designated Initializer.
 *
 * @param title          The title to display on the alert.
 * @param message        The main message of the alert.
 * @param preferredStyle This is not currently used.
 */

-(instancetype) initWithTitle: (NSString*)title
                      message: (NSString*)message
               preferredStyle: (UIAlertControllerStyle)preferredStyle  NS_DESIGNATED_INITIALIZER;


#pragma mark Actions


/*!
 * Adds an action if one is not already there.
 * 
 * The check is by pointer-equality, so e.g. two actions with the same text and handler would both appear.
 *
 * @param action An action. Will be added to the end of the alert's button list.
 */

-(void) addAction: (PWAction *)action;



/*!
 * Adds multiple actions in the order specified in the array.
 * 
 * @param actions An array of type PWAction. These actions will be added to the alert in the order they appear in the array.
 */

-(void) addActions: (NSArray *)actions;



/*!
 * All the actions currently added to the alert view. 
 */

@property (nonatomic, readonly) NSArray *actions;  // PWAlertAction objects.


#pragma mark Display

/*! 
 * If set, the alert will zoom out from this item (or otherwise indicate that popoverPresentationItem is its parent). 
 */

@property (nonatomic, strong) UIBarButtonItem *popoverPresentationItem;



/*! 
 * Construct the alert and display it. After this point, you cannot add any more actions. 
 */

-(void)show;


@end
