/*!
@header ErrorData
@abstract Some constants used for reporting errors and property keys.
@author Created by Patrick Wallace on 10/04/2015.
@copyright Copyright (c) 2015 Patrick Wallace. All rights reserved.
*/

@import Foundation;

    /*! Error domain for the Photo Store. */
static NSString * const kErrorDomainPhotoStore;

/*!
 * Error codes for common issues accessing the photo store.
 *
 * @constant ErrorCode_UnknownError               API failed without notifying why.
 * @constant ErrorCode_CouldntCreateSharedStore   Error creating the shared store directory
 * @constant ErrorCode_CouldntLoadImageProperties Error loading properties of a stereogram
 * @constant ErrorCode_InvalidFileFormat          Stereogram file format is not valid.
 * @constant ErrorCode_IndexOutOfBounds           Invalid index of stereogram in PhotoStore
 * @constant ErrorCode_FileNotFound               One of the stereogram's required files is missing.
 * @constant ErrorCode_NotImplemented             This code has not been implemented yet.
 * @constant ErrorCode_FeatureUnavailable         This operation requires a feature which your device doesn't have.
 *
 */
enum ErrorCodes {
    ErrorCode_UnknownError             =   1,
    ErrorCode_CouldntCreateSharedStore = 100,
    ErrorCode_CouldntLoadImageProperties    ,
    ErrorCode_InvalidFileFormat             ,
    ErrorCode_IndexOutOfBounds              ,
    ErrorCode_FileNotFound                  ,
    ErrorCode_NotImplemented                ,
    ErrorCode_FeatureUnavailable            ,
};

/*!
 * @functiongroup Keys of image properties.
 */

/*!
 * @constant kImagePropertyOrientation
 * Portrait or Landscape.
 */
extern NSString *const kImagePropertyOrientation;

/*! 
 * @constant  kImagePropertyThumbnail
 * Image thumbnail. 
 */
extern NSString *const kImagePropertyThumbnail;

/*! 
 * @constant kImagePropertyDateTaken
 * Date original photo was taken. 
 */
extern NSString *const kImagePropertyDateTaken;

/*! 
 * @constant kImagePropertyViewMode
 * Crosseyed, Walleyed, Red/Green, Random-dot etc. 
 */
extern NSString *const kImagePropertyViewMode;


    // Keys for loading and saving.

/*! 
 * @constant kVersion
 * Save file version. 
 */
extern NSString *const kVersion;
