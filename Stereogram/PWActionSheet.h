//
//  PWActionSheet.h
//  Stereogram
//
//  Created by Patrick Wallace on 30/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import <Foundation/Foundation.h>
@class PWAction;

@interface PWActionSheet : NSObject <UIActionSheetDelegate>

#pragma mark Constructors

    /// Designated initializer. Create a sheet with a title but no objects.
-(instancetype)initWithTitle: (NSString *)title NS_DESIGNATED_INITIALIZER;


#pragma mark Methods

    /// Add one action to the list that will be displayed.
-(void) addAction: (PWAction *)action;

    /// Add multiple actions to the list in the order they appear in the array (array of PWAction objects).
-(void) addActions:(NSArray *)actions;

// Passed through to the underlying UIAlertView.

-(void) showFromBarButtonItem:(UIBarButtonItem*)barButtonItem
                     animated:(BOOL)animated;

#pragma mark Properties

    /// List of actions provided for this object.
@property (nonatomic, readonly) NSArray *actions;

@end



#pragma mark -



typedef void (^PWActionHandler)(PWAction *action);

    /// This mimics UIAlertHandler (which is available in iOS8 only) for older architectures. Pass to a PWAlertView or PWActionSheet, and the handler will be called when the button with it's title is clicked.
@interface PWAction : NSObject

#pragma mark Constructors.

    /// Create a new action with a title, the style of Default, Cancel or Destructive and a callback handler.
+(instancetype) actionWithTitle: (NSString *)title
                          style: (UIAlertActionStyle)style
                        handler: (PWActionHandler)alertHandler;

    /// A new action with title and handler, default style of Default
+(instancetype) actionWithTitle:(NSString *)title
                        handler:(PWActionHandler)alertHandler;

    /// A cancel action has title of "Cancel", no handler and style of Cancel.
+(instancetype) cancelAction;

    /// Designated initializer. Each action takes a title, the style of Default, Cancel or Destructive and a callback handler.
-(instancetype) initWithTitle: (NSString *)title
                        style: (UIAlertActionStyle)style
                      handler: (PWActionHandler)alertHandler NS_DESIGNATED_INITIALIZER;

    /// Initialize the alert with a title and handler, and the default style of Default
-(instancetype) initWithTitle:(NSString *)title
                      handler:(PWActionHandler)alertHandler;

#pragma mark Methods

    /// Perform the action held in alertHandler.
- (void) act;

#pragma mark Properties

    /// Title to display.
@property (nonatomic, readonly) NSString *title;

    /// Style of the button.
@property (nonatomic, readonly) UIAlertActionStyle style;

@end
