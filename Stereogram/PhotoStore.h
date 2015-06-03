/*! @header PhotoStore
 *  @abstract PhotoStore is an object holding a collection of stereograms.
 *  @author Created by Patrick Wallace on 20/01/2013.
 *  @copyright Copyright (c) 2013 Patrick Wallace. All rights reserved.
 */

@import UIKit;
@class Stereogram;

NS_ASSUME_NONNULL_BEGIN

#pragma mark Error domain and codes

/*! This acts as a collection of stereograms and handles creating them from pairs of images. */
@interface PhotoStore : NSObject

/*! Number of stereograms stored in this photo store. */
@property (nonatomic, readonly) NSUInteger count;

/*! Size of an image thumbnail. */
@property (nonatomic, readonly) CGSize thumbnailSize;

/*! Constructor. If something fails it returns nil and an error. */
-(nullable instancetype) initWithFolderURL: (NSURL*)url
									 error: (NSError * __nullable *)error NS_DESIGNATED_INITIALIZER;

#pragma mark - Handling stereograms

/*!
 * An enumerator for running over all the stereograms in the store.
 */
@property (nonatomic, readonly) NSEnumerator *objectEnumerator;

/*! Adds the stereogram to the store. Assumes the stereogram has already been successfully created and saved.
 * @param stereogram The stereogram to add.
 *
 * If the stereogram is already contained, this will not add it twice.
 */
-(void) addStereogram: (Stereogram *)stereogram;


/*!
 * Create a new Stereogram object using the images provided and save it under a unique name under a base URL.
 *
 * @note This scales left and right images to 50% of their original size. This is to reduce memory pressure since the stereogram will be twice the size of its individual components.
 *
 * @param leftImage  The left-hand image in the stereogram.
 * @param rightImage The right-hand image in the stereogram.
 * @param errorPtr   A Pointer to an NSError object to return errors to the caller.
 * @returns A new Stereogram object or nil if something went wrong.
 */

-(nullable Stereogram *) createStereogramFromLeftImage: (UIImage *)leftImage
                                            rightImage: (UIImage *)rightImage
                                                 error: (NSError **)errorPtr;

/*! Retrieves a stereogram from the collection
 @return index The index of the stereogram to return.
 */
-(Stereogram *) stereogramAtIndex: (NSUInteger)index;

/*! Deletes the stereograms at the specified index paths.
 @param indexPaths An array of NSIndexPath objects referring to the stereograms to delete.
 @param errorPtr Optional pointer to an error object to return error information.
 @return YES if all deletes were successful, NO if one of the deletes returned an error.
 
 If any delete fails, this method stops at once with the error. No cleanup or rollback is done.
 */
-(BOOL) deleteStereogramsAtIndexPaths: (NSArray *)indexPaths
                                error: (NSError **)errorPtr;

/*! Delete a stereogram from disk and remove it from this collection.
 @param stereogram The stereogram to remove.
 @param errorPtr Optional pointer to an error object to return error information.
 @return YES if the deletes was successful, NO if the delete returned an error.
 */
-(BOOL) deleteStereogram: (Stereogram *)stereogram
                   error: (NSError **)errorPtr;

/*! Replaces a stereogram with a new one.
 @param index Index of the stereogram to replace.
 @param errorPtr Optional pointer to an error object to return error information.
 @return YES if the stereogram was replaced, NO if there was an error during the replacement.
 
 A stereogram must already exist to be replaced, otherwise this will return an error.
 */
-(BOOL) replaceStereogramAtIndex: (NSUInteger)index
                  withStereogram: (Stereogram *)newImage
                           error: (NSError **)errorPtr;

/*! Copies a stereogram into the device's camera roll.
 @param index The index of the stereogram to copy.
 @param errorPtr Optional pointer to an error object to return error information.
 @return YES if the copy was successful, NO if there was an error.
 */
-(BOOL) copyStereogramToCameraRoll: (NSUInteger)index
                             error: (NSError **)errorPtr;



@end


NS_ASSUME_NONNULL_END
