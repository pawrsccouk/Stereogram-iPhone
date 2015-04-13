//
//  PWAlertView.h
//  Stereogram
//
//  Created by Patrick Wallace on 30/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import <Foundation/Foundation.h>
@class PWAlertAction;

// A variant of NSAlertView which uses blocks instead of delegates.
// Internally calls UIAlertView with the delegate set to self, and handles the button text.

@interface PWAlertView : NSObject <UIAlertViewDelegate>

    /// Constructor. Give a title, a default message and style (which is not currently used).
+(instancetype) alertViewWithTitle: (NSString*)title
                           message: (NSString*)message
                    preferredStyle: (UIAlertControllerStyle)preferredStyle;

    /// Designated Initializer. Give a title, a default message and style (which is not currently used).
-(instancetype) initWithTitle: (NSString*)title
                      message: (NSString*)message
               preferredStyle: (UIAlertControllerStyle)preferredStyle  NS_DESIGNATED_INITIALIZER;

    /// Adds an action if one is not already there (checks by pointer-equality).
-(void) addAction: (PWAlertAction *)action;

    /// All the actions currently added to the alert view.
@property (nonatomic, readonly) NSArray *actions;  // PWAlertAction objects.

    /// If set, the alert will zoom out from this item (or otherwise indicate that popoverPresentationItem is its parent).
@property (nonatomic, strong) UIBarButtonItem *popoverPresentationItem;

    /// Construct the alert and display it. After this point, you cannot add any more actions.
-(void)show;


@end




#pragma mark -


    /// Callback handler for the PWAlert object. Called with the PWAlertAction which triggered the job.
typedef void(^PWAlertHandler)(PWAlertAction *action);

    /// This mimics UIAlertHandler (which is available in iOS8 only) for older architectures. Pass to a PWAlertView and the handler will be called when the button with it's title is clicked.
@interface PWAlertAction : NSObject

#pragma mark Constructors.

    /// Create a new action with a title, the style of Default, Cancel or Destructive and a callback handler.
+(instancetype) actionWithTitle: (NSString *)title
                          style: (UIAlertActionStyle)style
                        handler: (PWAlertHandler)alertHandler;

    /// A new action with title and handler, default style of Default
+(instancetype) actionWithTitle:(NSString *)title
                        handler:(PWAlertHandler)alertHandler;

    /// A cancel action has title of "Cancel", no handler and style of Cancel.
+(instancetype) cancelAction;

    /// Designated initializer. Each action takes a title, the style of Default, Cancel or Destructive and a callback handler.
-(instancetype) initWithTitle: (NSString *)title
                        style: (UIAlertActionStyle)style
                      handler: (PWAlertHandler)alertHandler NS_DESIGNATED_INITIALIZER;

    /// Initialize the alert with a title and handler, and the default style of Default
-(instancetype) initWithTitle:(NSString *)title
                      handler:(PWAlertHandler)alertHandler;

#pragma mark Methods

    /// Perform the action held in alertHandler.
- (void) act;

#pragma mark Properties

    /// Title to display.
@property (nonatomic, readonly) NSString *title;

    /// Style of the button.
@property (nonatomic, readonly) UIAlertActionStyle style;

@end
