//
//  PWAlertView.h
//  Stereogram
//
//  Created by Patrick Wallace on 30/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import <Foundation/Foundation.h>
@class PWAction;

// A variant of NSAlertView which uses blocks instead of delegates. Internally calls UIAlertView with the delegate set to self, and handles the button text.

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
-(void) addAction: (PWAction *)action;

    /// Adds multiple actions in the order specified in the array. (Array is of type PWAction *)
-(void) addActions: (NSArray *)actions;

    /// All the actions currently added to the alert view.
@property (nonatomic, readonly) NSArray *actions;  // PWAlertAction objects.

    /// If set, the alert will zoom out from this item (or otherwise indicate that popoverPresentationItem is its parent).
@property (nonatomic, strong) UIBarButtonItem *popoverPresentationItem;

    /// Construct the alert and display it. After this point, you cannot add any more actions.
-(void)show;


@end
