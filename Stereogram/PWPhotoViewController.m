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
#import "UIImage+Resize.h"

static NSString *const IMAGE_THUMBNAIL_CELL_ID = @"CollectionViewCell_Thumbnail";

@interface PWPhotoViewController () {
    PWCameraOverlayViewController *_cameraOverlayController;
    UIBarButtonItem *_exportItem, *_editItem;
    UIImage *_firstPhoto;
    UIImage *_stereogram;
    UIActivityIndicatorView *_activityIndicator;
    PWPhotoStore *_photoStore;
}
@end

@implementation PWPhotoViewController

-(instancetype) initWithPhotoStore: (PWPhotoStore *)photoStore {
    self = [super initWithNibName:@"PWPhotoView" bundle:nil];
    if (self) {
        _photoStore = photoStore;
        _cameraOverlayController = [[PWCameraOverlayViewController alloc] init];
        _stereogram = nil;

        UIBarButtonItem *takePhotoItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                                                                                       target:self
                                                                                       action:@selector(takePicture)];
        _exportItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                   target:self
                                                                   action:@selector(actionMenu)];
        _editItem = self.editButtonItem;
        self.navigationItem.rightBarButtonItems = @[takePhotoItem];
        self.navigationItem.leftBarButtonItems  = @[_exportItem, _editItem];
        self.editing = NO;
    }
    return self;
}

-(instancetype) init {
    self = [self initWithPhotoStore:nil];
    NSAssert(NO, @"PWPhotoViewController init: Use initWithPhotoStore: instead.");
    return nil;
}

static inline UICollectionViewFlowLayout* cast_UICollectionViewFlowLayout(id layout) {
    NSCAssert([layout isKindOfClass:[UICollectionViewFlowLayout class]], @"Photo collection layout is not a flow layout");
    return (UICollectionViewFlowLayout *)layout;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"PWPhotoViewController viewDidLoad self = %@", self);
    
    [photoCollection registerClass:[PWImageThumbnailCell class] forCellWithReuseIdentifier:IMAGE_THUMBNAIL_CELL_ID];
    photoCollection.allowsSelection = YES;
    photoCollection.allowsMultipleSelection = YES;
    
        // Set the thumbnail size from the store.
    UICollectionViewFlowLayout *flowLayout = cast_UICollectionViewFlowLayout(photoCollection.collectionViewLayout);
    flowLayout.itemSize = CGSizeMake(_photoStore.thumbnailSize, _photoStore.thumbnailSize);
    [flowLayout invalidateLayout];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)takePicture {
    if (! [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIAlertView *errorView = [[UIAlertView alloc] initWithTitle:@"No camera"
                                                            message:@"This device does not have a camera attached."
                                                           delegate:nil
                                                  cancelButtonTitle:@"Close"
                                                  otherButtonTitles:nil];
        [errorView show];
        return;
    }
    
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePickerController.mediaTypes = @[ (NSString*)kUTTypeImage ];
    imagePickerController.delegate = self;
    imagePickerController.showsCameraControls = NO;
    
        // setup our custom overlay view for the camera and ensure that our custom view's frame fits within the parent frame
    _cameraOverlayController.view.frame = imagePickerController.view.frame;

    imagePickerController.cameraOverlayView = _cameraOverlayController.view;
    _cameraOverlayController.helpText = @"Take the first photo";
    _cameraOverlayController.imagePickerController = imagePickerController;
    
    [self presentViewController:imagePickerController animated:YES completion:nil];
}


-(void) actionMenu {
    NSString * const photoGalleryButtonText = @"Copy to photo gallery",
             * const deleteButtonText = @"Delete", * const methodButtonText = @"Change viewing method",
             * const cancelButtonText = @"Cancel";
    NSDictionary *titlesAndActions = @{
    cancelButtonText       : ^{  },
    deleteButtonText       : ^{ deletePhotos(_photoStore, photoCollection);           },
    photoGalleryButtonText : ^{ copyPhotosToCameraRoll(_photoStore, photoCollection); },
    methodButtonText       : ^{ [self changeViewingMethod];              },
    };
    PWActionSheet *actionSheet = [[PWActionSheet alloc] initWithTitle:@"Action"
                                                buttonTitlesAndBlocks:titlesAndActions
                                                    cancelButtonTitle:cancelButtonText
                                               destructiveButtonTitle:deleteButtonText];
    [actionSheet showFromBarButtonItem:_exportItem
                              animated:YES];
}


-(void) setEditing: (BOOL)editing {
    [super setEditing:editing];
        // On turning off the editing option, clear the selection.
    if(!editing) {
        for (NSIndexPath *path in photoCollection.indexPathsForSelectedItems) {
            [photoCollection deselectItemAtIndexPath:path animated:NO];
        }
    }
}

    // Present an image view showing the image at the given index path.
-(void) showImageAtIndexPath: (NSIndexPath*)indexPath {
    NSError *error;
    UIImage *image = [_photoStore imageAtIndex:indexPath.item error:&error];
    if (image) {
        PWFullImageViewController *imageViewController = [[PWFullImageViewController alloc] initWithImage:image forApproval:NO];
        [self.navigationController pushViewController:imageViewController animated:YES];
    } else {
        [error showAlertWithTitle:[NSString stringWithFormat:@"Error accessing image at index %ld", (long)indexPath.item]];
    }
}


-(void) viewDidAppear: (BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"PhotoViewController viewDidAppear: self = %@", self);
        // If stereogram is set, we have just reappeared from under the camera controller, and we need to pop up
        // an approval window for the user to accept the new stereogram.
    if(_stereogram) {
        [self showApprovalWindowForImage:_stereogram];
        _stereogram = nil;
    }
}

-(void) showApprovalWindowForImage: (UIImage*)image {
    NSDate *dateTaken = [NSDate date];  // Declared outside the block in case the user spends a long time before approving the image.
    PWFullImageViewController *imageViewController = [[PWFullImageViewController alloc] initWithImage:image forApproval:YES];
    imageViewController.approvalBlock = ^{
        NSError *error = nil;
        if (![_photoStore addImage:image dateTaken:dateTaken error:&error]) {
            [error showAlertWithTitle:@"Error saving photo"];
        }
        [photoCollection reloadData];
    };
    UINavigationController *navC = [[UINavigationController alloc] initWithRootViewController:imageViewController];
    navC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:navC animated:YES completion:nil];
}

- (NSString *)description {
    NSString *superDescription = [super description];
    NSString *desc = [NSString stringWithFormat:@"%@ <_photoStore = %@>", superDescription, _photoStore];
    return desc;
}

#pragma mark - ImagePicker delegate

static UIImage *makeStereogram(PWPhotoStore *photoStore, UIImage *firstPhoto, UIImage *secondPhoto) {
    UIImage *stereogram = [photoStore makeStereogramWith:firstPhoto and:secondPhoto];
        // Halve the stereogram size as otherwise these end up way too big, since we've doubled the width of the image.
        // TODO: Make this an option to be checked in the preferences.
    return [stereogram resizedImage:CGSizeMake(stereogram.size.width / 2, stereogram.size.height / 2)
               interpolationQuality:kCGInterpolationHigh];
}

-(void) imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSAssert(_stereogram == nil, @"Stereogram %@ is not nil", _stereogram);
    
        // We need to get 2 photos, so the first time we enter here, we store the image and prompt the user to take the second photo.
        // Next time we enter here, we compose the 2 photos into the final montage and this is what we store. We also dismiss the photo chooser at that point.
    if(! _firstPhoto) {
        _firstPhoto = imageFromPickerInfoDict(info);
        _cameraOverlayController.helpText = @"Take the second photo";
    }
    else {
        UIImage *secondPhoto = imageFromPickerInfoDict(info);
        if(_firstPhoto && secondPhoto) {
            [_cameraOverlayController showWaitIcon:YES];
            
                // Create the stereogram as a background task, as it can take a while.
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                @try {
                    UIImage *stogram = makeStereogram(_photoStore, _firstPhoto, secondPhoto);
                        // Update the UI code back on the main thread.
                    dispatch_async(dispatch_get_main_queue(), ^{
                        _stereogram = stogram;
                        _firstPhoto = nil;
                        [picker dismissViewControllerAnimated:NO completion:nil];
                        [_cameraOverlayController showWaitIcon:NO];
                    });
                }
                @catch (NSException *exception) {
                    NSLog(@"Exception: %@", exception);
                }
            });
        }
    }
}

-(void) imagePickerControllerDidCancel: (UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
    _firstPhoto = nil;
}

#pragma mark - UICollectionView data source

-(NSInteger) numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}

-(NSInteger) collectionView: (UICollectionView *)collectionView numberOfItemsInSection: (NSInteger)section {
    NSAssert(section == 0, @"There should only be 1 section in our collection view, but section was %ld", (long)section);
    return _photoStore.count;
}

-(UICollectionViewCell *) collectionView: (UICollectionView *)collectionView cellForItemAtIndexPath: (NSIndexPath *)indexPath {
    PWImageThumbnailCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:IMAGE_THUMBNAIL_CELL_ID forIndexPath:indexPath];
    // Populate the cell
    NSError *error = nil;
    UIImage *image = [_photoStore thumbnailAtIndex:indexPath.item error:&error];
    if(!image && error) {
        NSLog(@"Error retrieving image at index %ld from photoStore %@, indexPath %@", (long)indexPath.item, _photoStore, indexPath);
        NSLog(@"Error was %@ (%@)", error, error.userInfo);
    }
    cell.image = image;
    return cell;
}

#pragma mark - UICollectionView delegate

-(void)   collectionView: (UICollectionView *)collectionView
didSelectItemAtIndexPath: (NSIndexPath *)indexPath {
        // In editing mode, this doesn't need to do anything as the status flag on the cell has already been updated.
        // In viewing mode, we need to revert this status-flag update, and then pop the full-image view onto the navigation stack.
    if(! self.editing) {
        [collectionView deselectItemAtIndexPath:indexPath animated:NO];
        [self showImageAtIndexPath:indexPath];
    }
}

-(void)     collectionView: (UICollectionView *)collectionView
didDeselectItemAtIndexPath: (NSIndexPath *)indexPath {
        // If we are in viewing mode, then we any click on a thumbnail -to select or deselect- we translate into
        // a request to show the full-image view.
    if(! self.editing) {
        [self showImageAtIndexPath:indexPath];
    }
}

#pragma mark - Private methods

static NSString *formatDeleteMessage(NSUInteger numToDelete) {
    NSString * const postscript = @"This operation cannot be undone.";
    return numToDelete == 1 ? [NSString stringWithFormat:@"Do you really want to delete this photo?\n%@", postscript]
                            : [NSString stringWithFormat:@"Do you really want to delete these %lu photos?\n%@", (unsigned long)numToDelete, postscript];
}


    // A shared method that does something to one of the photos. Takes a block holding the action to perform.
    // The block takes an integer, which is an index into the collection of image thumbnails in the order they appear
    // in the collection view.  The action must not invalidate the collection view indexes as it may be called more than once.
typedef BOOL (^ActionBlock)(NSUInteger, NSError * __autoreleasing *);
static void performNondestructiveAction(UICollectionView *photoCollection, ActionBlock action, NSString *errorTitle) {
    for (NSIndexPath *indexPath in photoCollection.indexPathsForSelectedItems) {
        NSError *errorPtr = nil;
        if (!action([indexPath indexAtPosition:1], &errorPtr)) {
            [errorPtr showAlertWithTitle:errorTitle];
            return; // Exit to avoid showing the user multiple errors
        }
        [photoCollection deselectItemAtIndexPath:indexPath animated:NO];
    }
}

static void copyPhotosToCameraRoll(PWPhotoStore *photoStore, UICollectionView *photoCollection) {
    performNondestructiveAction(photoCollection, ^(NSUInteger index, NSError * __autoreleasing *errorPtr) {
                                    return [photoStore copyImageToCameraRoll:index error:errorPtr]; }, @"Error exporting to camera roll");
}

-(void)showActivityIndicator:(BOOL) showIndicator
{
    if(! _activityIndicator) {
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        CGSize activitySize = _activityIndicator.bounds.size;
        CGSize parentBounds = self.view.bounds.size;
        CGRect frame = CGRectMake((parentBounds.width  / 2) - (activitySize.width  / 2),
                                  (parentBounds.height / 2) - (activitySize.height / 2),
                                  activitySize.width,
                                  activitySize.height);
        _activityIndicator.frame = frame;
    }
    
    if (showIndicator) {
        [self.view addSubview:_activityIndicator];
        _activityIndicator.hidden = NO;
        [_activityIndicator startAnimating];
    }
    else {
        [_activityIndicator stopAnimating];
        _activityIndicator.hidden = YES;
        [_activityIndicator removeFromSuperview];
    }
}

-(void) changeViewingMethod {
    [self showActivityIndicator:YES];
    
        // Take a deep copy of the selected items, in case another thread manipulates them while I'm working.
    NSArray *selectedItems = [photoCollection.indexPathsForSelectedItems copy];
    
        // Convert the image in a background thread (it can take a while), showing a progress wheel to the user.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        for (NSIndexPath *indexPath in selectedItems) {
            NSAssert([indexPath indexAtPosition:0] == 0, @"Index Path %@ not for section 0", indexPath);
            NSError *error = nil;
            if (![_photoStore changeViewingMethod:[indexPath indexAtPosition:1] error:&error]) {    // Index path has format [<section>, <item>].
                dispatch_async(dispatch_get_main_queue(), ^{
                    [error showAlertWithTitle:@"Error changing viewing method"];
                    [self showActivityIndicator:NO];
                });
                return; // Exit to avoid showing the user multiple errors
            }
        }
            // Back on the main thread, deselect all the selected thumbnails, and stop the activity timer.
        dispatch_async(dispatch_get_main_queue(), ^{
            for(NSIndexPath *indexPath in selectedItems) {
                [photoCollection deselectItemAtIndexPath:indexPath animated:YES];
            }
            [self showActivityIndicator:NO];
            [photoCollection reloadItemsAtIndexPaths:selectedItems];
        });
    });
}

static void deletePhotos(PWPhotoStore *photoStore, UICollectionView *photoCollection)
{
    NSArray *indexPaths = photoCollection.indexPathsForSelectedItems;
    if(indexPaths.count > 0) {
        
        void (^doDelete)() =  ^(){
            NSError *error = nil;
            if (![photoStore deleteImagesAtIndexPaths:indexPaths error:&error]) {
                [error showAlertWithTitle:@"Error deleting photos"];
            }
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
}

static UIImage *imageFromPickerInfoDict(NSDictionary *infoDict)
{
    UIImage *photo =       infoDict[UIImagePickerControllerEditedImage];
    return photo ? photo : infoDict[UIImagePickerControllerOriginalImage];
}



@end
