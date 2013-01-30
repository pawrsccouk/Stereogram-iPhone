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
        
        actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                  delegate:self
                                         cancelButtonTitle:nil
                                    destructiveButtonTitle:nil
                                         otherButtonTitles:nil];
        NSInteger cancelIndex = -1, destructiveIndex = -1;
        for(NSString *title in buttonTitlesAndBlocks.allKeys) {
            NSInteger index = [actionSheet addButtonWithTitle:title];
            if     ([title isEqualToString:cancelButtonTitle     ])  cancelIndex      = index;
            else if([title isEqualToString:destructiveButtonTitle])  destructiveIndex = index;
        }
        if(cancelIndex      >= 0) { actionSheet.cancelButtonIndex      = cancelIndex;      }
        if(destructiveIndex >= 0) { actionSheet.destructiveButtonIndex = destructiveIndex; }
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
    NSString *buttonTitle = [sheet buttonTitleAtIndex:buttonIndex];
    PWActionSheet_Action action = [buttonTitlesAndBlocks objectForKey:buttonTitle];
    NSAssert(action, @"No action found for button title [%@] index %d", buttonTitle, buttonIndex);
    if(action)
        action();
    [self.class removeAReference:self];
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
