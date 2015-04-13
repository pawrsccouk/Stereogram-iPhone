//
//  PWActionSheet.m
//  Stereogram
//
//  Created by Patrick Wallace on 30/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import "PWActionSheet.h"

@interface PWActionSheet () {
    UIActionSheet *_actionSheet;
    NSMutableArray *_actions; // Of type PWAction
}
@end

@implementation PWActionSheet

-(instancetype) initWithTitle: (NSString *)title {
    self = [super init];
    if (!self) { return nil; }
    _actions = [NSMutableArray array];
    _actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                               delegate:self
                                      cancelButtonTitle:nil
                                 destructiveButtonTitle:nil
                                      otherButtonTitles:nil];
    return self;
}



-(void) showFromBarButtonItem: (UIBarButtonItem *)barButtonItem
                     animated: (BOOL)animated {
//    [self.class keepAReference:self];
    NSAssert(_actionSheet.delegate == self, @"Delegate %@ is not self", _actionSheet.delegate);
//    _actionSheet.delegate = self;
    
    for (PWAction *action in self.actions) {
        NSUInteger index = [_actionSheet addButtonWithTitle:action.title];
        switch (action.style) {
            case UIAlertActionStyleCancel:      _actionSheet.cancelButtonIndex      = index; break;
            case UIAlertActionStyleDestructive: _actionSheet.destructiveButtonIndex = index; break;
            default: break;  // UIAlertActionStyleDefault is the other option. No changes needed for that.
        }
    }
    
    [_actionSheet showFromBarButtonItem:barButtonItem
                               animated:animated];
}

- (NSArray *)actions {
    return _actions;
}

-(void) addAction: (PWAction *)newAction {
    if (![_actions containsObject:newAction]) {
        [_actions addObject:newAction];
    }
}

-(void) addActions: (NSArray *)newActions {
    for (PWAction *newAction in newActions) {
        NSAssert([newAction isMemberOfClass:[PWAction class]], @"Object [%@] in actions array is not of type PWAction", newAction);
        [self addAction:newAction];
    }
}

#pragma mark Action Sheet delegate

-(void)  actionSheet:(UIActionSheet *)sheet
clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSLog(@"actionSheet:clickedButtonAtIndex: sheet = %@, index = %ld", sheet, (long)buttonIndex);
        // If the user didn't specify a cancel handler, the system can trigger a cancel anyway under some conditions
        // e.g. user clicks outside the popover on an iPad. In that case the system should return the cancel index, but it
        // actually returns -1. Handle this.
    if( buttonIndex != -1) {
            // The user clicked a button. Get the action for that button and execute it.
        NSString *buttonTitle = [sheet buttonTitleAtIndex:buttonIndex];
        PWAction *action = self.actions[buttonIndex];
        NSAssert(action, @"No action found for button title [%@] index %ld", buttonTitle, (long)buttonIndex);
        if(action) {
            [action act];
        }
    }
}

@end


#pragma mark -


@interface PWAction () {
    PWActionHandler _handler;
}

@end

    /// This mimics UIAlertHandler (which is available in iOS8 only) for older architectures. Pass to a PWAlertView and the handler will be called when the button with it's title is clicked.
@implementation PWAction
@synthesize title = _title, style = _style;

#pragma mark Constructors.

    /// Create a new action with a title, the style of Default, Cancel or Destructive and a callback handler.
+(instancetype) actionWithTitle: (NSString *)title
                          style: (UIAlertActionStyle)style
                        handler: (PWActionHandler)alertHandler {
    return [[PWAction alloc] initWithTitle:title
                                     style:style
                                   handler:alertHandler];
    
}

    /// A new action with title and handler, default style of Default
+(instancetype) actionWithTitle:(NSString *)title
                        handler:(PWActionHandler)alertHandler {
    return [[PWAction alloc] initWithTitle:title
                                   handler:alertHandler];
}

    /// A cancel action has title of "Cancel", no handler and style of Cancel.
+(instancetype) cancelAction {
    return [PWAction actionWithTitle:@"Cancel"
                                style:UIAlertActionStyleCancel
                              handler:nil];
}

    /// Designated initializer. Each action takes a title, the style of Default, Cancel or Destructive and a callback handler.
-(instancetype) initWithTitle: (NSString *)title
                        style: (UIAlertActionStyle)style
                      handler: (PWActionHandler)alertHandler {
    self = [super init];
    if (!self) { return nil; }
    
    _style = style;
    _title = [title copy];
    _handler = alertHandler;
    
    return self;
}

    /// Initialize the alert with a title and handler, and the default style of Default
-(instancetype) initWithTitle:(NSString *)title
                      handler:(PWActionHandler)alertHandler {
    return [self initWithTitle:title
                         style:UIAlertActionStyleDefault
                       handler:alertHandler];
}

#pragma mark Methods

    /// Perform the action held in alertHandler.
- (void) act {
    if (_handler) {
        _handler(self);
    }
}

@end

