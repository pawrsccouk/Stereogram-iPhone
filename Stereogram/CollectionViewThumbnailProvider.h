//
//  CollectionViewThumbnailProvider.h
//  Stereogram
//
//  Created by Patrick Wallace on 13/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PWPhotoStore;

    // Connector that takes a thumbnail provider and implements a collection view delegate, serving data from the provider.
    // TODO: Make this generic

@interface CollectionViewThumbnailProvider : NSObject <UICollectionViewDataSource>

-(instancetype) initWithPhotoStore: (PWPhotoStore *)photoStore
                        collection: (UICollectionView*)photoCollection;

@end
