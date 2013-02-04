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
#import "PWAlertView.h"
#import "PWActionSheet.h"

static NSString *const IMAGE_THUMBNAIL_CELL_ID = @"CollectionViewCell_Thumbnail";

@interface PWPhotoViewController ()

@end

@implementation PWPhotoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:@"PWPhotoView" bundle:nibBundleOrNil];
    if (self) {
        cameraOverlayController = [[PWCameraOverlayViewController alloc] init];
        stereogram = nil;

        UIBarButtonItem *takePhotoItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                                                                                       target:self
                                                                                       action:@selector(takePicture)];
        exportItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                   target:self
                                                                   action:@selector(exportMenu)];
        editItem = self.editButtonItem;
        self.navigationItem.rightBarButtonItems = @[takePhotoItem];
        self.navigationItem.leftBarButtonItems  = @[exportItem, editItem];
        self.editing = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [photoCollection registerClass:[PWImageThumbnailCell class] forCellWithReuseIdentifier:IMAGE_THUMBNAIL_CELL_ID];
    photoCollection.allowsSelection = YES;
    photoCollection.allowsMultipleSelection = YES;
    
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
        UIAlertView *errorView = [[UIAlertView alloc] initWithTitle:@"No camera"
                                                            message:@"This device does not have a camera attached."
                                                           delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil];
        [errorView show];
        return;
    }
    
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePickerController.mediaTypes = @[ (NSString*)kUTTypeImage ];
    imagePickerController.delegate = self;
    imagePickerController.showsCameraControls = NO;
    
        // setup our custom overlay view for the camera
        //
        // ensure that our custom view's frame fits within the parent frame
    cameraOverlayController.view.frame = imagePickerController.view.frame;

    imagePickerController.cameraOverlayView = cameraOverlayController.view;
    cameraOverlayController.instructionLabel.text = @"Take the first photo";
    cameraOverlayController.imagePickerController = imagePickerController;
    
    [self presentViewController:imagePickerController animated:YES completion:nil];
}


-(void)exportMenu
{
    NSString * const photoGalleryButtonText = @"Copy to photo gallery",
             * const deleteButtonText = @"Delete",
             * const cancelButtonText = @"Cancel";
    NSDictionary *titlesAndActions = @{
    cancelButtonText       : ^{  },
    deleteButtonText       : ^{ deletePhotos(photoCollection);           },
    photoGalleryButtonText : ^{ copyPhotosToCameraRoll(photoCollection); }
    };
    PWActionSheet *actionSheet = [[PWActionSheet alloc] initWithTitle:@"Action"
                                                buttonTitlesAndBlocks:titlesAndActions
                                                    cancelButtonTitle:cancelButtonText
                                               destructiveButtonTitle:deleteButtonText];
    [actionSheet showFromBarButtonItem:exportItem animated:YES];
}


-(void)setEditing:(BOOL)editing
{
    [super setEditing:editing];
        // On turning off the editing option, clear the selection.
    if(!editing)
        for (NSIndexPath *path in photoCollection.indexPathsForSelectedItems)
            [photoCollection deselectItemAtIndexPath:path animated:NO];
}

    // Present an image view showing the image at the given index path.
-(void)showImageAtIndexPath:(NSIndexPath*)indexPath
{
    NSError *error;
    UIImage *image = [[PWPhotoStore sharedStore] imageAtIndex:indexPath.item error:&error];
    if (! image) {
        [error showAlertWithTitle:[NSString stringWithFormat:@"Error accessing image at index %d", indexPath.item]];
        return;
    }
    PWFullImageViewController *imageViewController = [[PWFullImageViewController alloc] initWithImage:image forApproval:NO];
    [self.navigationController pushViewController:imageViewController animated:YES];
}


-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
        // If stereogram is set, we have just reappeared from under the camera controller, and we need to pop up
        // an approval window for the user to accept the new stereogram.
    if(stereogram) {
        UIImage *image = stereogram;
        stereogram = nil;

        PWFullImageViewController *imageViewController = [[PWFullImageViewController alloc] initWithImage:image forApproval:YES];
        imageViewController.approvalBlock = ^ {
            NSError *error = nil;
            if(! [[PWPhotoStore sharedStore] addImage:image error:&error])
                [error showAlertWithTitle:@"Error saving photo"];
            [photoCollection reloadData];
        };
        UINavigationController *navC = [[UINavigationController alloc] initWithRootViewController:imageViewController];
        navC.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:navC animated:YES completion:nil];
    }
}

#pragma mark - ImagePicker delegate

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSAssert(stereogram == nil, @"Stereogram %@ is not nil", stereogram);

        // We need to get 2 photos, so the first time we enter here, we store the image and prompt the user to take the second photo.
        // Next time we enter here, we compose the 2 photos into the final montage and this is what we store. We also dismiss the photo chooser at that point.
    if(! firstPhoto) {
        firstPhoto = imageFromPickerInfoDict(info);
        cameraOverlayController.instructionLabel.text = @"Take the second photo";
    }
    else {
        UIImage *secondPhoto = imageFromPickerInfoDict(info);
        if(firstPhoto && secondPhoto)
            stereogram = [[PWPhotoStore sharedStore] makeStereogramWith:firstPhoto and:secondPhoto];

        firstPhoto = nil;
        [picker dismissViewControllerAnimated:NO completion:nil];
    }
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    firstPhoto = nil;
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
        // In editing mode, this doesn't need to do anything as the status flag on the cell has already been updated.
        // In viewing mode, we need to revert this status-flag update, and then pop the full-image view onto the navigation stack.
    if(! self.editing) {
        [collectionView deselectItemAtIndexPath:indexPath animated:NO];
        [self showImageAtIndexPath:indexPath];
    }
}

-(void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
        // If we are in viewing mode, then we any click on a thumbnail -to select or deselect- we translate into
        // a request to show the full-image view.
    if(! self.editing)
        [self showImageAtIndexPath:indexPath];
}

#pragma mark - Private methods

static NSString *formatDeleteMessage(NSUInteger numToDelete)
{
    NSString * const postscript = @"This operation cannot be undone.";
    return numToDelete == 1 ? [NSString stringWithFormat:@"Do you really want to delete this photo?\n%@", postscript]
                            : [NSString stringWithFormat:@"Do you really want to delete these %d photos?\n%@", numToDelete, postscript];
}

static void copyPhotosToCameraRoll(UICollectionView *photoCollection)
{
    PWPhotoStore *photoStore = [PWPhotoStore sharedStore];
    NSError *error = nil;
    for (NSIndexPath *indexPath in photoCollection.indexPathsForSelectedItems) {
        if(! [photoStore copyImageToCameraRoll:indexPath.item error:&error]) {
            [error showAlertWithTitle:@"Error exporting to camera roll"];
            return; // Exit to avoid showing the user multiple errors
        }
        [photoCollection deselectItemAtIndexPath:indexPath animated:NO];
    }
}


static void deletePhotos(UICollectionView *photoCollection)
{
    NSArray *indexPaths = photoCollection.indexPathsForSelectedItems;
    PWPhotoStore *photoStore = [PWPhotoStore sharedStore];
    if(indexPaths.count > 0) {
        
        void (^doDelete)() =  ^(){
            NSError *error = nil;
            if(! [photoStore deleteImagesAtIndexPaths:indexPaths error:&error])
                [error showAlertWithTitle:@"Error deleting photos"];
            [photoCollection reloadData];  // Reload to prevent thumbnails being out of sync with photos.
       };
        
        PWAlertView *alertView = [[PWAlertView alloc] initWithTitle:@"Confirm deletion"
                                                            message:formatDeleteMessage(indexPaths.count)
                                                 confirmButtonTitle:@"Delete"
                                                       confirmBlock:doDelete
                                                  cancelButtonTitle:@"Cancel"
                                                        cancelBlock: ^{}];
        [alertView show];
    }
};

static UIImage *imageFromPickerInfoDict(NSDictionary *infoDict)
{
    UIImage *photo =       infoDict[UIImagePickerControllerEditedImage];
    return photo ? photo : infoDict[UIImagePickerControllerOriginalImage];
}



@end
