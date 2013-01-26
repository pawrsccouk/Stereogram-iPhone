//
//  PWPhotoViewController.m
//  Stereogram
//
//  Created by Patrick Wallace on 20/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import "PWPhotoViewController.h"
#import "MobileCoreServices/UTCoreTypes.h"
#import "PWPhotoStore.h"
#import "NSError_AlertSupport.h"
#import "PWImageThumbnailCell.h"
#import "PWFullImageViewController.h"
#import "PWCameraOverlayViewController.h"

static NSString *const IMAGE_THUMBNAIL_CELL_ID = @"CollectionViewCell_Thumbnail";

@interface PWPhotoViewController ()

@end

@implementation PWPhotoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:@"PWPhotoView" bundle:nibBundleOrNil];
    if (self) {
        UIBarButtonItem *takePhotoItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                                                                                       target:self
                                                                                       action:@selector(takePicture)];
//        UIBarButtonItem *refreshItem = [[UIBarButtonItem alloc] initWithTitle:@"Refresh"
//                                                                        style:UIBarButtonItemStylePlain
//                                                                       target:self
//                                                                       action:@selector(refreshView)];
        self.navigationItem.rightBarButtonItems = @[takePhotoItem];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [photoCollection registerClass:[PWImageThumbnailCell class] forCellWithReuseIdentifier:IMAGE_THUMBNAIL_CELL_ID];
    
        // Set the thumbnail size from the store.
    NSAssert([photoCollection.collectionViewLayout isKindOfClass:[UICollectionViewFlowLayout class]], @"Photo collection layout is not a flow layout");
    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout*)photoCollection.collectionViewLayout;
    PWPhotoStore *store = [PWPhotoStore sharedStore];
    flowLayout.itemSize = CGSizeMake(store.thumbnailSize, store.thumbnailSize);
    [flowLayout invalidateLayout];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)takePicture
{
    if (! [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"No camera"
                                                            message:@"This device does not have a camera attached."
                                                           delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil];
        [alertView show];
        return;
    }
    
    UIImagePickerController *cameraController = [[UIImagePickerController alloc] init];
    cameraController.sourceType = UIImagePickerControllerSourceTypeCamera;
    cameraController.mediaTypes = @[ (NSString*)kUTTypeImage ];
    cameraController.delegate = self;
    
    cameraOverlayController = [[PWCameraOverlayViewController alloc] init];
    cameraController.cameraOverlayView = cameraOverlayController.view;
    
    [self presentViewController:cameraController animated:YES completion:nil];
}

-(void)refreshView
{
    [photoCollection reloadData];
}

#pragma mark - ImagePicker delegate

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    PWPhotoStore *photoStore = [PWPhotoStore sharedStore];
    
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage] ? [info objectForKey:UIImagePickerControllerEditedImage]
                                                                            : [info objectForKey:UIImagePickerControllerOriginalImage];
    if(image) {
        NSError *error = nil;
        if(! [photoStore addImage:image error:&error])
            [error showAlertWithTitle:@"Error saving photo"];
        [photoCollection reloadData];
    }

    [picker dismissViewControllerAnimated:YES completion:nil];
    cameraOverlayController = nil;
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    cameraOverlayController = nil;
}

#pragma mark - UICollectionView data source

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSAssert(section == 0, @"There should only be 1 section in our collection view, but section was %d", section);
    return [PWPhotoStore sharedStore].count;
//    return 0;   // TODO Fix
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PWImageThumbnailCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:IMAGE_THUMBNAIL_CELL_ID forIndexPath:indexPath];
    // Populate the cell
    NSError *error;
    PWPhotoStore *photoStore = [PWPhotoStore sharedStore];
    UIImage *image = [photoStore thumbnailAtIndex:indexPath.item error:&error];
    if(!image && error) {
        NSLog(@"Error retrieving image at index %d from photoStore %@, indexPath %@", indexPath.item, photoStore, indexPath);
        NSLog(@"Error was %@ (%@)", error, error.userInfo);
    }
    cell.image = image;
    return cell;
}

#pragma mark - UICollectionView delegate

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSError *error;
    UIImage *image = [[PWPhotoStore sharedStore] imageAtIndex:indexPath.item error:&error];
    if (! image) {
        [error showAlertWithTitle:[NSString stringWithFormat:@"Error accessing image at index %d", indexPath.item]];
        return;
    }
    PWFullImageViewController *imageViewController = [[PWFullImageViewController alloc] initWithImage:image];
    [self.navigationController pushViewController:imageViewController animated:YES];
}

@end
