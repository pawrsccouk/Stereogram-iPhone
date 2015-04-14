//
//  CollectionViewThumbnailProvider.m
//  Stereogram
//
//  Created by Patrick Wallace on 13/04/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

#import "CollectionViewThumbnailProvider.h"
#import "PWImageThumbnailCell.h"
#import "PWPhotoStore.h"

static NSString * const THUMBNAIL_CELL_ID = @"ImageThumbnailCell";


@interface CollectionViewThumbnailProvider () {
    PWPhotoStore *_photoStore;
    UICollectionView *_photoCollection;
}

@end

    // Connector that takes a thumbnail provider and implements a collection view delegate, serving data from the provider.
    // TODO: Make this generic
@implementation CollectionViewThumbnailProvider

-(instancetype) initWithPhotoStore: (PWPhotoStore *)photoStore
                        collection: (UICollectionView *)photoCollection {
    self = [super init];
    if (!self) { return nil; }
    
    _photoStore = photoStore;
    _photoCollection = photoCollection;
    _photoCollection.dataSource = self;
    [_photoCollection registerClass:PWImageThumbnailCell.class
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
    PWImageThumbnailCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:THUMBNAIL_CELL_ID
                                                                           forIndexPath: indexPath];
    NSError *error = nil;
    UIImage *image = [_photoStore thumbnailAtIndex:indexPath.item
                                             error:&error];
    if (image) {
        cell.image = image;
    } else {
        NSLog(@"Error receiving image at %@ from photoStore %@", indexPath, _photoStore);
        NSLog(@"The error was %@", error);
    }
    return cell;
}

@end
