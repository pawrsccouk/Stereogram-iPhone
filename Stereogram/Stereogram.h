/*! 
 @header Stereogram
 @author Patrick Wallace
 @copyright (c) 2015 Patrick Wallace. All rights reserved.
 @abstract This contains the Stereogram class, used for representing a pair of images and some associated properties.
*/

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/*!
 * @enum
 * @brief The ways of displaying the stereogram image.
 * @constant ViewingMethod_CrossEye    Images shown side-by-side with cross-eyed view
 * @constant ViewingMethod_WallEye     Images shown side-by-side with wall-eyed view
 * @constant ViewingMethod_AnimatedGIF Images shown as frames in an animation
 *
 * See 
 * @link //apple_ref/occ/instm/Stereogram/stereogramImage: @/link
 */
typedef enum ViewingMethod {
    ViewingMethod_CrossEye,
    ViewingMethod_WallEye,
    ViewingMethod_AnimatedGIF,
    
    ViewingMethod_NUM_METHODS
} ViewingMethod;

/*! 
 * @class Stereogram
 * This holds data for one stereogram and can load and save it if given a file URL.
 * The data is stored in one directory per stereogram, with the left and right images and properties stored under that.
 * Properties are stored as Apple property-lists.
 *
 * The actual stereogram object only has 3 URLs -to the left and right images and a properties file. The actual images and the generated images are cached in the object but can be released following a memory-notification.  They will be recomputed when needed next.
 */
@interface Stereogram : NSObject

/*! Size of the thumbnails that thumbnailImage will provide.
 */
+(CGSize) thumbnailSize;

/*! 
 Create a new stereogram from two images and save it to disk.
 @param baseURL The directory to put the new object in.
 @param leftImage The first image in the stereogram.
 @param rightImage The second image in the stereogram
 @param errorPtr Optional error information if something went wrong.
 @return A new object referencing the data given or nil if something went wrong.
 @note This saves the images to disk, then initialises a new stereogram with the new filenames.
 */
+(nullable instancetype) createAndSaveFromLeftImage: (UIImage *)leftImage
                                         rightImage: (UIImage *)rightImage
                                            baseURL: (NSURL *)baseURL
                                              error: (NSError * __nullable *)errorPtr;

/*! 
 * Load all the stereograms in a given directory and return them in an array.
 * @param url The base directory to search. Must be a file URL pointing to a directory.
 * @param errorPtr Optional error information if something went wrong.
 * @return An array of Stereogram objects which were found in the directory.
 */
+(NSArray *) allStereogramsUnderURL: (NSURL*)url
                              error: (NSError * __nullable *)errorPtr;


/*!
 * Initialize this object by loading image data from the specified URL.
 *
 *
 *
 * @param errorPtr Optional error information if something went wrong.
 * @return A new Stereogram if successful, nil if not.
 *
 * Convenience initializer.
 */
+(nullable instancetype) stereogramWithURL: (NSURL *)url
                                     error: (NSError * __nullable *)errorPtr;



#pragma mark -

/*! 
 * @property viewingMethod
 * The current way the user wants to display this stereogram. Affects the result of stereogramImage.
 */
@property (nonatomic) enum ViewingMethod viewingMethod;

/*! 
 * Combine leftImage and rightImage according to viewingMethod.
 * @param errorPtr Optional error information if something went wrong.
 * @return The new stereogram image if successful, nil if not.
 *
 * The stereogram image is cached for future requests, but the cache may be released if we hit a low-memory warning.
 * So calling this method could take an unacceptable amount of time.
 *
 * See also @link refresh: @/link for how to deal with this.
 */
-(nullable UIImage *) stereogramImage: (NSError * __nullable *)errorPtr;

/*! 
 * Return a thumbnail image for this stereogram.
 * @param errorPtr Optional error information if something went wrong.
 * @return The new thumbnail image if successful, nil if not.
 *
 * The thumbnail image is cached for future requests, but the cache may be released if we hit a low-memory warning. This shouldn't be a problem as it doesn't take long to reload it from disk.
 */
-(nullable UIImage *) thumbnailImage: (NSError * __nullable *)errorPtr;

/*! 
 * Update the stereogram and thumbnail, replacing the cached images.
 *
 * Usually called from a background thread just after some property has been changed. This allows the caller to change the images or viewing method and regenerate the images while displaying a wait cursor. Once generated the system should use the cached image for future requests.
 * @param errorPtr Optional error information if something went wrong.
 * @return YES if successful, NO if not.
 */
-(BOOL) refresh: (NSError * __nullable *)errorPtr;

/*! Delete the folder representing this error from the disk.
 * @param errorPtr Optional error information if something went wrong.
 * @return YES if successful, NO if not.
 */
-(BOOL) deleteFromDisk: (NSError * __nullable *)errorPtr;

#pragma mark Initializers

/*!
 * Initialize this object with a left and a right image and a viewing mode.
 *
 * @param baseURL A file URL to the root directory for this stereogram.  The left and right images will be stored under this.
 * @param propertyList An Apple-format property dictionary for this stereogram.
 *
 * Designated initializer.
 */
-(instancetype) initWithBaseURL: (NSURL *)baseURL
                   propertyList: (NSMutableDictionary *)propertyList
    NS_DESIGNATED_INITIALIZER;


@end

NS_ASSUME_NONNULL_END
