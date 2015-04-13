//
//  PWAlertView.m
//  Stereogram
//
//  Created by Patrick Wallace on 30/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import "PWAlertView.h"
#import "PWFunctional.h"


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


- (void) addAction: (PWAlertAction *)action {
    NSAssert(!_presenting, @"Invalid state: _presenting = %@", _presenting ? @"YES" : @"NO");
    if (![_actions containsObject:action]) {
        [_actions addObject:action];
    }
}

-(NSArray *) actions {
    return _actions;
}


-(void) show {
    NSAssert(!_presenting, @"Invalid state: _presenting = %@", _presenting ? @"YES" : @"NO");
//   [self.class keepAReference:self];
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
    PWAlertAction *action = self.actions[buttonIndex];
    NSAssert(action, @"No action for button title [%@] at index %ld", buttonTitle, (long)buttonIndex);
    if(action) {
        [action act];
    }
    _presenting = NO;
//    [self.class removeAReference:self];
}


//#pragma mark Private methods
//
//    // These three are used to ensure there is always a strong reference to the view and it'll not go out of scope.
//    // I'll add a reference when the view is shown, and remove it when a button is selected (when the view is dismissed).
//+(NSMutableArray *) arrayOfActiveViews {
//    static NSMutableArray *activeViews = nil;
//    if(!activeViews)
//        activeViews = [NSMutableArray array];
//    return activeViews;
//}
//
//+(void) keepAReference: (PWAlertView*)view {
//    [[self arrayOfActiveViews] addObject:view];
//}
//
//+(void)removeAReference: (PWAlertView*)view {
//    [[self arrayOfActiveViews] removeObject:view];
//}

@end



#pragma mark -



@interface PWAlertAction () {
    PWAlertHandler _handler;
}

@end

@implementation PWAlertAction
@synthesize title = _title, style = _style;

#pragma mark Constructors

+(instancetype) actionWithTitle: (NSString *)title
                          style: (UIAlertActionStyle)style
                        handler: (PWAlertHandler)handler {
    return [[PWAlertAction alloc] initWithTitle:title
                                          style:style
                                        handler:handler];
}

+(instancetype)actionWithTitle:(NSString *)title
                       handler:(PWAlertHandler)alertHandler {
    return [[PWAlertAction alloc]initWithTitle:title
                                       handler:alertHandler];
}

+(instancetype) cancelAction {
    return [self actionWithTitle:@"Cancel"
                           style:UIAlertActionStyleCancel
                         handler:nil];
}

-(instancetype) initWithTitle: (NSString *)title
                        style: (UIAlertActionStyle)style
                      handler: (PWAlertHandler)handler {
    self = [super init];
    if (!self) { return nil; }
    _title = title;
    _style = style;
    _handler = handler;
    return self;
}

-(instancetype) initWithTitle:(NSString *)title
                      handler:(PWAlertHandler)alertHandler {
    return [self initWithTitle:title
                         style:UIAlertActionStyleDefault
                       handler:alertHandler];
}

#pragma mark Methods

-(void) act {
    if (_handler) {
        _handler(self);
    }
}

@end

