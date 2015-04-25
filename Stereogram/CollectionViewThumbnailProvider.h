/*!
 * @file CollectionViewThumbnailProvider.h
 * @author Patrick Wallace on 13/04/2015.
 * @copyright 2015 Patrick Wallace. All rights reserved.
 */

@import UIKit;
@class PhotoStore;

/*! Connector that takes a thumbnail provider and implements a collection view delegate, serving data from the provider.
 *
 * @todo Make this generic
 */
@interface CollectionViewThumbnailProvider : NSObject <UICollectionViewDataSource>

/*!
 * Designated initializer. 
 *
 * @param photoStore The store to search for thumbnails.
 * @param photoCollection The collection which will ask the receiver for thumbnail data.
 */
-(instancetype) initWithPhotoStore: (PhotoStore *)photoStore
                        collection: (UICollectionView*)photoCollection NS_DESIGNATED_INITIALIZER;

@end
