/*!
 * @file PWActionSheet.h
 * @author Patrick Wallace on 30/01/2013.
 * @copyright 2013 Patrick Wallace. All rights reserved.
 */

@import Foundation;
@class PWAction;

/*!
 * A version of UIActionSheet which uses blocks instead of a delegate.
 *
 * Internally calls UIAlertView with the delegate set to self, and handles the button text.
 * Similar to UIAlertController which we can switch to if we only want to target iOS8.
 */
@interface PWActionSheet : NSObject <UIActionSheetDelegate>

#pragma mark Constructors

/*!
 * Designated initializer. Create a sheet with a title but no objects.
 *
 * @param title          The title to display on the alert.
 */
-(instancetype)initWithTitle: (NSString *)title NS_DESIGNATED_INITIALIZER;


#pragma mark Methods

/*!
 * Add one action to the list that will be displayed.
 *
 * @param action The action object to add to the view.
 */
-(void) addAction: (PWAction *)action;

/*!
 * Add multiple actions to the list in the order they appear in the array.
 *
 * @param array an array of PWAction objects.
 */
-(void) addActions: (NSArray *)actions;

    // Passed through to the underlying UIAlertView.

/*!
 * Present this view to the user as if it originated from the toolbar button provided.
 *
 * @param barButtonItem The alert will appear as if originating from this toolbar button.
 * @param animated If YES, the alert view's appearance will be animated.
 */
-(void) showFromBarButtonItem: (UIBarButtonItem*)barButtonItem
                     animated: (BOOL)animated;

#pragma mark Properties

/*!
 * List of actions the receiver will display.
 */
@property (nonatomic, readonly) NSArray *actions;

@end



#pragma mark -


/*!
 * This is the type of a block which will be executed when the user selects the corresponding action in the sheet.
 */
typedef void (^PWActionHandler)(PWAction *action);

/*!
 * This object represents one action. An action sheet is made up of actions which are presented to the user as a menu or buttons on a popup dialog. The title of each item is displayed on the GUI and if the user selects that control, the block associated with the action is executed.
 *
 * This mimics UIAlertHandler (which is available in iOS8 only) for older architectures.
 */
@interface PWAction : NSObject

#pragma mark Constructors.

/*!
 * Convenience constructor. Returns a new object initialized with initWithTitle:style:handler:.
 *
 * @param title The text to display on the GUI for this action.
 * @param style How to display this control.
 * @param handler Callback block which will be executed when the control for this action is clicked.
 */
+(instancetype) actionWithTitle: (NSString *)title
                          style: (UIAlertActionStyle)style
                        handler: (PWActionHandler)alertHandler;

/*!
 * Convenience constructor.  Returns a new action using the default style.
 *
 * @param title The text to display on the GUI for this action.
 * @param alertHandler Callback block which will be executed when the control for this action is clicked.
 */
+(instancetype) actionWithTitle:(NSString *)title
                        handler:(PWActionHandler)alertHandler;

/*!
 * Return an new action with title of "Cancel", no handler and style of Cancel.
 */
+(instancetype) cancelAction;

/*! Designated initializer.
 *
 * @param title The text to display on the GUI for this action.
 * @param style How to display this control.
 * @param alertHandler Callback block which will be executed when the control for this action is clicked.
 */
-(instancetype) initWithTitle: (NSString *)title
                        style: (UIAlertActionStyle)style
                      handler: (PWActionHandler)alertHandler NS_DESIGNATED_INITIALIZER;

/*!
 * Initialize the action with the default style.
 *
 * @param title The text to display on the GUI for this action.
 * @param alertHandler Callback block which will be executed when the control for this action is clicked.
 */
-(instancetype) initWithTitle:(NSString *)title
                      handler:(PWActionHandler)alertHandler;

#pragma mark Methods

    /*!
     * Perform the action held in alertHandler.
     */
- (void) act;

#pragma mark Properties

    /*!
     * Title to display in the control representing this action.
     */
@property (nonatomic, readonly) NSString *title;

    /*!
     * Style of the button. This determines how, where and if the item is drawn.
     * 
     * Some items may be removed on some architectures
     * (for example iPad doesn't always need a cancel button as the user can click somewhere else, so that may be automatically removed.
     */
@property (nonatomic, readonly) UIAlertActionStyle style;

@end
