//
//  PWAlertView.m
//  Stereogram
//
//  Created by Patrick Wallace on 30/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import "PWAlertView.h"
#import "PWFunctional.h"
#import "PWActionSheet.h"


@interface PWAlertView () {
    UIAlertView *_alertView;
    NSMutableArray*_actions; // Key = title, value = PWAlertAction object.
    BOOL _presenting;
}
@end

@implementation PWAlertView
@synthesize popoverPresentationItem = _popoverPresentationItem;

+(instancetype) alertViewWithTitle: (NSString *)title
                           message: (NSString *)message
                    preferredStyle: (UIAlertControllerStyle)preferredStyle {
    return [[PWAlertView alloc] initWithTitle:title
                                      message:message
                               preferredStyle:preferredStyle];
}

-(instancetype) initWithTitle: (NSString *)title
                      message: (NSString *)message
               preferredStyle: (UIAlertControllerStyle)preferredStyle {
    self = [super init];
    if (!self) { return nil; }
    
    _presenting = NO;
    _alertView = [[UIAlertView alloc] initWithTitle:title
                                            message:message
                                           delegate:self
                                  cancelButtonTitle:nil
                                  otherButtonTitles:nil];
    _actions = [NSMutableArray array];
    return self;
}


-(void) addAction: (PWAction *)action {
    NSAssert(!_presenting, @"Invalid state: _presenting = %@", _presenting ? @"YES" : @"NO");
    if (![_actions containsObject:action]) {
        [_actions addObject:action];
    }
}

-(void) addActions: (NSArray *)actions {
    for (PWAction *action in actions) {
        [self addAction:action];
    }
}

-(NSArray *) actions {
    return _actions;
}


-(void) show {
    NSAssert(!_presenting, @"Invalid state: _presenting = %@", _presenting ? @"YES" : @"NO");
    _presenting = YES;
    
    for (UIAlertAction *action in self.actions) {
            // Note: Destructive events are not shown specially here. Alerts only show for destructive events anyway so all actions are assumed to be destructive or cancel.
        int index = [_alertView addButtonWithTitle:action.title];
        if (action.style == UIAlertActionStyleCancel) {
            _alertView.cancelButtonIndex = index;
        }
    }
    [_alertView show];
}

#pragma mark Alert View Delegate

-(void)    alertView: (UIAlertView *)alertView
clickedButtonAtIndex: (NSInteger)buttonIndex {
    NSString *buttonTitle = [_alertView buttonTitleAtIndex:buttonIndex];
    NSAssert(_presenting, @"State error: view %@ _presenting = NO in delegate callback", self);
        // Find the specified action and trigger it.
    PWAction *action = self.actions[buttonIndex];
    NSAssert(action, @"No action for button title [%@] at index %ld", buttonTitle, (long)buttonIndex);
    if(action) {
        [action act];
    }
    _presenting = NO;
}

@end
