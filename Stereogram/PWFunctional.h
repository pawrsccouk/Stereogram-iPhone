//
//  PWFunctional.h
//  CharSheet
//
//  Created by Patrick Wallace on 13/12/2012.
//
//  General purpose small support classes not worth their own file.

#import <Foundation/Foundation.h>


typedef BOOL(^PWArraySimpleBlockPredicate)(id object);
typedef id  (^PWArrayTransformBlock      )(id object);
typedef id  (^PWArrayReduceBlock)         (id oldObject, id newObject);

@interface NSArray (ArraySimplifiers)
    // Simple wrapper around filteredArrayUsingPredicate that creates the predicate
    // and ignores the binding dict.
-(NSArray*)filteredArrayUsingBlock:(PWArraySimpleBlockPredicate)block;

    // Returns a new array where each element is formed by calling block() on the item
    // in the existing array.
-(NSArray*)transformedArrayUsingBlock:(PWArrayTransformBlock)block;

    // Same as transformedArrayUsingBlock, but the calls to block can be on separate threads.
    // Use this version if the call to block() could take some time, and so could be better run in parallel.
    // If block uses any shared data, it will need to synchronise access to it.
-(NSArray *)transformedArrayAsyncUsingBlock:(PWArrayTransformBlock)block;


    // Call reduce on the array. This method calls <block> on the first 2 values
    // of the array, then again with the result of that and the next value and so on.
    // Returns the final result, the first item (if the array has only one item) or nil if the array is empty.
-(id)reducedArrayUsingBlock:(PWArrayReduceBlock)block;

    // This version takes a starting value, and calls <block> with that value
    // and the first element, then goes through the subsequent elements calling block
    // on the results.  Returns <value> if the array is empty.
-(id)reducedArrayUsingBlock:(PWArrayReduceBlock)block startingValue:(id)value;

@end


