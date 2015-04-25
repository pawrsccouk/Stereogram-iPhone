/*!
 * @file PWFunctional.h
 * @abstract General purpose small support classes not worth their own file.
 *
 * @author Patrick Wallace on 13/12/2012.
 * @copyright 2013 Patrick A Wallace, all rights reserved.
 */
@import Foundation;

/*!
 * Type of a predicate block used for filters. 
 *
 * @param object The object to test.
 * @returns YES or NO. 
 */
typedef BOOL(^PWArraySimpleBlockPredicate)(id object);

/*! 
 * Type of a block passed to transform functions. This takes an object, performs some conversion on it and returns the new object.
 *
 * @param object The object passed in from the array.
 * @return A new object which is the result of transforming OBJECT.
 */
typedef id  (^PWArrayTransformBlock      )(id object);

/*!
 * Type of block passed to reduce functions. 
 *
 * This takes an object from the array and an object which was the result of a previous call to the block.
 * It returns an object which will be passed to the next reduce block and so on until the final result is returned from the reduce function.
 */
typedef id  (^PWArrayReduceBlock)         (id oldObject, id newObject);


/*!
 * Extensions to NSArray to enable or simplify functional programming.
 */
@interface NSArray (ArraySimplifiers)

/*!
 * Simple wrapper around filteredArrayUsingPredicate that creates the predicate and ignores the binding dict.
 *
 * @param block Predicate function which will be called to see which objects to include in the block.
 * @return An array containing only the entries where block returned YES.
 */
-(NSArray*)filteredArrayUsingBlock:(PWArraySimpleBlockPredicate)block;

/*!
 * Returns a new array where each element is formed by calling block() on the item in the existing array.
 *
 */
-(NSArray*)transformedArrayUsingBlock:(PWArrayTransformBlock)block;

/*! Same as transformedArrayUsingBlock, but the calls to block can be on separate threads.
 *
 * Use this version if the call to block() could take some time, and so could be better run in parallel.
 * If block uses any shared data, it will need to synchronise access to it.
 *
 * @param block This will be called once for each element to return the elements to appear in the output array.
 * @return An array containing the transformed objects.
 */
-(NSArray *)transformedArrayAsyncUsingBlock:(PWArrayTransformBlock)block;


/*!
 * Call reduce on the array. This method calls <block> on the first 2 values of the array,
 * then again with the result of that and the next value and so on.
 * @param block Function which will be called with each successive item in the array
 *              and the result of the call to block() for the previous element in the array.
 * @return The final result: the first item (if the array has only one item) or nil if the array is empty.
 */
-(id)reducedArrayUsingBlock:(PWArrayReduceBlock)block;

/*!
 * Calls BLOCK with parameters of VALUE and the first element in the array, 
 * then calls it for each of the subsequent elements, passing in the result of calling BLOCK with the previous element.
 *
 * @param block Function which will be called with each successive item in the array
 *              and the result of the call to block() for the previous element in the array.
 * @param value A starting value for the reduce. Will be passed into the first call of BLOCK
 * @return VALUE if the array is empty, otherwise the result of BLOCK called for the final element.
 */
-(id)reducedArrayUsingBlock:(PWArrayReduceBlock)block startingValue:(id)value;

@end


