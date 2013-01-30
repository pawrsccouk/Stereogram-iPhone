//
//  PWAlertView.m
//  Stereogram
//
//  Created by Patrick Wallace on 30/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import "PWAlertView.h"
#import "PWFunctional.h"

@implementation PWAlertView

-(id)   initWithTitle:(NSString*)title
              message:(NSString*)message
buttonTitlesAndBlocks:(NSDictionary *)titlesAndBlocks
    cancelButtonTitle:(NSString *)cancelTitle
{
    self = [super init];
    if(self) {
        buttonTitlesAndBlocks  = [titlesAndBlocks  copy];
        cancelButtonTitle      = [cancelTitle      copy];
    
        NSAssert(cancelButtonTitle ? [buttonTitlesAndBlocks.allKeys containsObject:cancelButtonTitle] : YES,
                 @"cancel title %@ not in blocks list", cancelButtonTitle);
        
        alertView = [[UIAlertView alloc] initWithTitle:title
                                               message:message
                                              delegate:self
                                     cancelButtonTitle:nil
                                     otherButtonTitles:nil];
        NSInteger cancelIndex = -1;
        for (NSString *title in buttonTitlesAndBlocks.allKeys) {
            NSInteger buttonIndex = [alertView addButtonWithTitle:title];
            if(cancelButtonTitle && [title isEqualToString:cancelButtonTitle])
                cancelIndex = buttonIndex;
        }
        if(cancelIndex >= 0) { alertView.cancelButtonIndex = cancelIndex; }
    }
    return self;
}

-(id)initWithTitle:(NSString *)title
           message:(NSString *)message
confirmButtonTitle:(NSString *)confirmTitle
      confirmBlock:(PWAlertView_Action  )confirmBlock
 cancelButtonTitle:(NSString *)cancelTitle
       cancelBlock:(PWAlertView_Action  )cancelBlock
{
    return [self initWithTitle:title
                       message:message
         buttonTitlesAndBlocks:@{confirmTitle : confirmBlock, cancelTitle : cancelBlock}
             cancelButtonTitle:cancelTitle];
}

-(void)show
{
    [self.class keepAReference:self];
    [alertView show];
}

#pragma mark - Alert View Delegate

-(void)alertView:(UIAlertView *)alertview clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [alertview buttonTitleAtIndex:buttonIndex];
    PWAlertView_Action action = [buttonTitlesAndBlocks objectForKey:buttonTitle];
    NSAssert(action, @"No action for button title [%@] at index %d", buttonTitle, buttonIndex);
    if(action)
        action();
    [self.class removeAReference:self];
}


#pragma mark - Private methods

    // These three are used to ensure there is always a strong reference to the view and it'll not go out of scope.
    // I'll add a reference when the view is shown, and remove it when a button is selected (when the view is dismissed).
+(NSMutableArray*)arrayOfActiveViews
{
    static NSMutableArray *activeViews = nil;
    if(!activeViews)
        activeViews = [NSMutableArray array];
    return activeViews;
}

+(void)keepAReference:(PWAlertView*)view
{
    [[self arrayOfActiveViews] addObject:view];
}

+(void)removeAReference:(PWAlertView*)view
{
    [[self arrayOfActiveViews] removeObject:view];
}

@end
