/*! 
 @header Stereogram
 @author Patrick Wallace
 @copyright (c) 2015 Patrick Wallace. All rights reserved.
 @abstract This contains the Stereogram class, used for representing a pair of images and some associated properties.
*/

@import UIKit;

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
 * Create a new stereogram from two images.
 *
 * @param directoryURL A File URL pointing to a parent directory. The new stereogram will be given a unique name and stored in here.
 * @param leftImage The left image to store.
 * @param rightIamge The right image to store.
 * @param errorPtr Optional pointer to an object to pass error information back to the caller.
 * @return Either a new Stereogram object or nil if something failed.
 */

+(instancetype) stereogramWithDirectoryURL: (NSURL * )directoryURL
                                 leftImage: (UIImage *)leftImage
                                rightImage: (UIImage *)rightImage
                                     error: (NSError **)errorPtr;



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
                   propertyList: (NSDictionary *)propertyList
NS_DESIGNATED_INITIALIZER;



/*!
 * Initialize a stereogram from two images.
 *
 * @param directoryURL A File URL pointing to a parent directory. The new stereogram will be given a unique name and stored in here.
 * @param leftImage The left image to store.
 * @param rightIamge The right image to store.
 * @param errorPtr Optional pointer to an object to pass error information back to the caller.
 * @return Either a new Stereogram object or nil if something failed.
 */

-(instancetype) initWithDirectoryURL: (NSURL * )directoryURL
                           leftImage: (UIImage *)leftImage
                          rightImage: (UIImage *)rightImage
                               error: (NSError **)errorPtr;



#pragma mark Properties

	/*!
	 * URL to the root of the directory, under which we'll find the left and right images.
	 * Used to load the images when needed.
	 */
@property (nonatomic, readonly) NSURL *baseURL;


/*!
 * @property viewingMethod
 * The current way the user wants to display this stereogram. Affects the result of stereogramImage.
 */
@property (nonatomic) enum ViewingMethod viewingMethod;


#pragma mark Methods


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
 * Return the image representation data in a form suitable for exporting beyond this application.
 * For example, in an email or written out to a file.
 *
 * @param mimeTypePtr Pointer to a string which will be passed the MIME type of the data.
 * @param errorPtr    Optional pointer to an NSError object which if set will be provided if something went wrong.
 * @return A populated NSData object on success, or nil and a value in errorPtr on failure.
 */
-(nullable NSData *) exportDataWithMimeType: (NSString * __nullable * __nonnull )mimeTypePtr
                                      error: (NSError * __nullable *)errorPtr;

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

@end

NS_ASSUME_NONNULL_END
