//
//  PWAlertView.h
//  Stereogram
//
//  Created by Patrick Wallace on 30/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import <Foundation/Foundation.h>

// A variant of NSAlertView which uses blocks instead of delegates.
// Internally calls UIAlertView with the delegate set to self, and handles the button text.

@interface PWAlertView : NSObject <UIAlertViewDelegate>

typedef void(^PWAlertView_Action)(void);

-(id)    initWithTitle:(NSString*)title
               message:(NSString*)message
 buttonTitlesAndBlocks:(NSDictionary *)titlesAndBlocks
     cancelButtonTitle:(NSString *)cancelTitle;

-(id)initWithTitle:(NSString*)title
           message:(NSString*)message
confirmButtonTitle:(NSString*)confirmTitle
      confirmBlock:(PWAlertView_Action )confirmBlock
 cancelButtonTitle:(NSString*)cancelTitle
       cancelBlock:(PWAlertView_Action )cancelBlock;

-(void)show;

@end
