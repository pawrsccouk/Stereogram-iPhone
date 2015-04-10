//
//  PWActionSheet.h
//  Stereogram
//
//  Created by Patrick Wallace on 30/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PWActionSheet : NSObject <UIActionSheetDelegate>

    // Type of an action to perform.
typedef void (^PWActionSheet_Action)(void);



// Designated initialiser - Take a list of buttons titles and blocks, then optionally single one out for cancel
// and one for destructive operations (either can be nil).

-(id)    initWithTitle:(NSString*)title
 buttonTitlesAndBlocks:(NSDictionary *)buttonTitlesAndBlocks
     cancelButtonTitle:(NSString*)cancelButtonTitle
destructiveButtonTitle:(NSString*)destructiveTitle NS_DESIGNATED_INITIALIZER;


// Shorthand constructor for an action sheet with an OK and Cancel buttons (and blocks to match them).

-(id)initWithTitle:(NSString*)title
confirmButtonTitle:(NSString*)confirmTitle
      confirmBlock:(PWActionSheet_Action )confirmBlock
 cancelButtonTitle:(NSString*)cancelButtonTitle
       cancelBlock:(PWActionSheet_Action )cancelBlock;

// As above, but the OK button is marked as destructive and will be highlighted on the UI.

-(id)    initWithTitle:(NSString*)title
destructiveButtonTitle:(NSString*)destructTitle
      destructiveBlock:(PWActionSheet_Action) destructBlock
     cancelButtonTitle:(NSString*)cancelButtonTitle
           cancelBlock:(PWActionSheet_Action) cancelBlock;


// Passed through to the underlying UIAlertView.

-(void) showFromBarButtonItem:(UIBarButtonItem*)barButtonItem animated:(BOOL)animated;

@end
