//
//  NSError_AlertSupport.h
//  Stereogram
//
//  Created by Patrick Wallace on 21/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

@import Foundation;
#import "UIKit/UIKit.h"
#import "ErrorData.h"

@implementation NSError (AlertSupport)

-(void) showAlertWithTitle: (NSString *)title
      parentViewController: (UIViewController *)parentViewController {
    NSString *errorText = self.helpAnchor ? self.helpAnchor
    : self.localizedFailureReason ? self.localizedFailureReason
    : self.localizedDescription;
    
// UIAlertController only valid in iOS 8.
//    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
//                                                                             message:errorText
//                                                                      preferredStyle:UIAlertControllerStyleAlert];
//
//    [parentViewController presentViewController:alertController
//                                       animated:YES
//                                     completion:nil];

    NSLog(@"Presenting view for error %@, userInfo: %@", self, self.userInfo);
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:errorText
                                                       delegate:nil
                                              cancelButtonTitle:@"Close"
                                              otherButtonTitles:nil];
    [alertView show];
}

NSString *const kLocationKey = @"Location", *const kCallerKey = @"Caller", *const kTargetKey = @"Target";
NSString *const kParameterKey = @"Parameter", *const kParameterValueKey = @"ParameterValue";



+(NSError *) unknownErrorWithLocation: (NSString *)location {
    NSString *errorText = [NSString stringWithFormat:@"Unknown error in %@", location];
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorText,
                                kLocationKey              : location.copy
                                };
    return [NSError errorWithDomain: kErrorDomainPhotoStore
                                         code: ErrorCode_UnknownError
                                     userInfo: userInfo];
}




+(NSError *) unknownErrorWithCaller: (NSString *)caller
                             target: (id)target
                             method: (SEL)method {
    NSString *methodString = NSStringFromSelector(method);
    NSString *errorText = [NSString stringWithFormat: @"Unknown error in [%@ %@] called from %@", [target class], methodString, caller];
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorText   ,
                                kTargetKey                : target      ,
                                kLocationKey              : methodString,
                                kCallerKey                : caller      , };
    return [NSError errorWithDomain: kErrorDomainPhotoStore
                               code: ErrorCode_UnknownError
                           userInfo: userInfo];
}


+(NSError*) parameterErrorWithNilParameter: (NSString *)parameterName {
	NSString *errorText = [NSString stringWithFormat: @"Parameter %@ is nil.", parameterName];
	NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorText
								, kParameterKey           : parameterName };
	return [NSError errorWithDomain:kErrorDomainPhotoStore
							   code:ErrorCode_InvalidParameter
						   userInfo:userInfo];
}

+(NSError *) parameterErrorWithParameter: (NSString *)parameterName
							 valuePassed: (id)value {
	NSString *errorText = [NSString stringWithFormat: @"Parameter %@ is not valid. It was %@", parameterName, value];
	NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorText
								, kParameterKey           : parameterName
								, kParameterValueKey      : value };
	return [NSError errorWithDomain:kErrorDomainPhotoStore
							   code:ErrorCode_InvalidParameter
						   userInfo:userInfo];
}

@end
