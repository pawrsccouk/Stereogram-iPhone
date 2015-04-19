//
//  CollectionViewThumbnailProvider.m
//  Stereogram
//
//  Created by Patrick Wallace on 13/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

#import "CollectionViewThumbnailProvider.h"
#import "ImageThumbnailCell.h"
#import "Stereogram.h"
#import "PhotoStore.h"

static NSString * const THUMBNAIL_CELL_ID = @"ImageThumbnailCell";


@interface CollectionViewThumbnailProvider () {
    PhotoStore *_photoStore;
    UICollectionView *_photoCollection;
}

@end

    // Connector that takes a thumbnail provider and implements a collection view delegate, serving data from the provider.
    // TODO: Make this generic
@implementation CollectionViewThumbnailProvider

-(instancetype) initWithPhotoStore: (PhotoStore *)photoStore
                        collection: (UICollectionView *)photoCollection {
    self = [super init];
    if (!self) { return nil; }
    
    _photoStore = photoStore;
    _photoCollection = photoCollection;
    _photoCollection.dataSource = self;
    [_photoCollection registerClass:ImageThumbnailCell.class
         forCellWithReuseIdentifier:THUMBNAIL_CELL_ID];

    return self;
}




    
#pragma mark - Collection View Data Source

-(NSInteger) numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}

-(NSInteger) collectionView: (UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    return _photoStore.count;
}

-(UICollectionViewCell *) collectionView: (UICollectionView *)collectionView
                  cellForItemAtIndexPath: (NSIndexPath *)indexPath {
    ImageThumbnailCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:THUMBNAIL_CELL_ID
                                                                           forIndexPath: indexPath];
    NSError *error = nil;
    Stereogram *stereogram = [_photoStore stereogramAtIndex:indexPath.item];
    NSAssert(stereogram, @"Error receiving stereogram at indexPath %@ from photoStore %@", indexPath, _photoStore);
    cell.image = [stereogram thumbnailImage:&error];
    NSAssert(cell.image, @"Error receiving image from stereogram %@. Error was %@", stereogram, error);
    return cell;
}

@end
