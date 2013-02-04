//
//  PWActionSheet.m
//  Stereogram
//
//  Created by Patrick Wallace on 30/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import "PWActionSheet.h"

@implementation PWActionSheet

-(id)    initWithTitle:(NSString *)title
 buttonTitlesAndBlocks:(NSDictionary *)titlesAndBlocks
     cancelButtonTitle:(NSString *)cancelTitle
destructiveButtonTitle:(NSString *)destructiveTitle
{
    self = [super init];
    if(self) {
        buttonTitlesAndBlocks = [titlesAndBlocks copy];
        destructiveButtonTitle = [destructiveTitle copy];
        cancelButtonTitle      = [cancelTitle copy];
        
        NSMutableDictionary *otherButtons = [NSMutableDictionary dictionaryWithDictionary:buttonTitlesAndBlocks];
        if(cancelButtonTitle     ) { [otherButtons removeObjectForKey:cancelButtonTitle     ]; }
        if(destructiveButtonTitle) { [otherButtons removeObjectForKey:destructiveButtonTitle]; }

        actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                  delegate:self
                                         cancelButtonTitle:nil
                                    destructiveButtonTitle:nil
                                         otherButtonTitles:nil];
        
        // Add the destructive button first (if any) and the cancel button last.
        // Note that the iPad action sheet will always hide the cancel button as you are supposed to click outside
        // the sheet to cancel it. This will generate a call to the delegate with the index of the cancel button automatically.
        if(destructiveButtonTitle)
            actionSheet.destructiveButtonIndex = [actionSheet addButtonWithTitle:destructiveButtonTitle];
        
        for(NSString *title in otherButtons.allKeys)
            [actionSheet addButtonWithTitle:title];
        
        if(cancelButtonTitle)
            actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:cancelButtonTitle];
    }
    return self;
}

-(id)initWithTitle:(NSString *)title
confirmButtonTitle:(NSString *)confirmTitle
      confirmBlock:(PWActionSheet_Action  )confirmBlock
 cancelButtonTitle:(NSString *)cancelTitle
       cancelBlock:(PWActionSheet_Action  )cancelBlock
{
    return [self initWithTitle:title
         buttonTitlesAndBlocks:@{confirmTitle : confirmBlock, cancelTitle : cancelBlock}
             cancelButtonTitle:cancelTitle
        destructiveButtonTitle:nil];
}


-(id)    initWithTitle:(NSString *)title
destructiveButtonTitle:(NSString *)destructTitle
      destructiveBlock:(PWActionSheet_Action  )destructBlock
     cancelButtonTitle:(NSString *)cancelTitle
           cancelBlock:(PWActionSheet_Action  )cancelBlock
{
    return [self initWithTitle:title
         buttonTitlesAndBlocks:@{destructTitle : destructBlock, cancelTitle : cancelBlock}
             cancelButtonTitle:cancelTitle
        destructiveButtonTitle:destructTitle];
}

-(void)showFromBarButtonItem:(UIBarButtonItem *)barButtonItem animated:(BOOL)animated
{
    [self.class keepAReference:self];
    NSAssert(actionSheet.delegate == self, @"Delegate %@ is not self", actionSheet.delegate);
    [actionSheet showFromBarButtonItem:barButtonItem animated:animated];
}

#pragma mark - Action Sheet delegate

-(void)actionSheet:(UIActionSheet *)sheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    @try {
            // If the user didn't specify a cancel handler, the system can trigger a cancel anyway under some conditions
            // e.g. user clicks outside the popover on an iPad. In that case the system should return the cancel index, but it
            // actually returns -1. Handle both these conditions.
        if( (buttonIndex == -1) || ( (! cancelButtonTitle) && (buttonIndex == actionSheet.cancelButtonIndex)) )
            return;
        
            // Otherwise the user clicked a button. Get the action for that button and execute it.
        NSString *buttonTitle = [sheet buttonTitleAtIndex:buttonIndex];
        PWActionSheet_Action action = [buttonTitlesAndBlocks objectForKey:buttonTitle];
        NSAssert(action, @"No action found for button title [%@] index %d", buttonTitle, buttonIndex);
        if(action)
            action();
    }
    @finally {
        [self.class removeAReference:self];
    }
}

#pragma mark - Private methods

// These three are used to ensure there is always a strong reference to the sheet and it'll not go out of scope.
// I'll add a reference when the sheet is shown, and remove it when a button is selected.
+(NSMutableArray*)arrayOfActiveSheets
{
    static NSMutableArray *activeSheets = nil;
    if(!activeSheets)
        activeSheets = [NSMutableArray array];
    return activeSheets;
}

+(void)keepAReference:(PWActionSheet*)sheet
{
    [[self arrayOfActiveSheets] addObject:sheet];
}

+(void)removeAReference:(PWActionSheet*)sheet
{
    [[self arrayOfActiveSheets] removeObject:sheet];
}

@end
