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
#import "ImageManager.h"
#import "CollectionViewThumbnailProvider.h"

static NSString *const IMAGE_THUMBNAIL_CELL_ID = @"CollectionViewCell_Thumbnail";

static NSString *formatDeleteMessage(NSUInteger numToDelete);
static inline UICollectionViewFlowLayout* cast_UICollectionViewFlowLayout(id layout);
static inline UIImage *imageFromPickerInfoDict(NSDictionary *infoDict);

#pragma mark - 

@interface PWPhotoViewController () {
    PWCameraOverlayViewController *_cameraOverlayController;
    UIBarButtonItem *_exportItem, *_editItem;
    UIImage *_firstPhoto, *_stereogram;
    UIActivityIndicatorView *_activityIndicator;
    CollectionViewThumbnailProvider *_thumbnailProvider;
    PWAlertView *_alertView;
    PWActionSheet *_actionSheet;
}
@end

@implementation PWPhotoViewController
@synthesize photoStore = _photoStore;

-(instancetype) initWithPhotoStore: (PWPhotoStore *)photoStore {
    self = [super initWithNibName:@"PWPhotoView" bundle:nil];
    if (self) {
        _photoStore = photoStore;
        _cameraOverlayController = [[PWCameraOverlayViewController alloc] init];
        _stereogram = nil;
        _thumbnailProvider = nil;
        _actionSheet = nil;
        _alertView = nil;
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
    return [self initWithPhotoStore:nil];
}

- (void) viewDidLoad {
    [super viewDidLoad];
    NSLog(@"PWPhotoViewController viewDidLoad self = %@", self);
    
    [photoCollectionView registerClass:[PWImageThumbnailCell class] forCellWithReuseIdentifier:IMAGE_THUMBNAIL_CELL_ID];
    photoCollectionView.allowsSelection = YES;
    photoCollectionView.allowsMultipleSelection = YES;
    
        // Set the thumbnail size from the store.
    UICollectionViewFlowLayout *flowLayout = cast_UICollectionViewFlowLayout(photoCollectionView.collectionViewLayout);
    flowLayout.itemSize = _photoStore.thumbnailSize;
    [flowLayout invalidateLayout];

        // Pass a provider to copy data from the model to the collection view.
    _thumbnailProvider = [[CollectionViewThumbnailProvider alloc] initWithPhotoStore:_photoStore
                                                                          collection:photoCollectionView];
}

- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

    /// Kick off the picture-taking process. Present the camera view controller with our custom overlay on top.
-(void) takePicture {
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

    /// Create and display an action menu with the items available for a set of the collection items.
-(void) actionMenu {
    PWAction *cancelAction = [PWAction cancelAction];
    
    PWActionHandler deleteBlock = ^(PWAction *action) {
        [self deletePhotos:photoCollectionView];
    };
    PWAction *deleteAction = [PWAction actionWithTitle:@"Delete"
                                                 style:UIAlertActionStyleDestructive
                                               handler:deleteBlock];
    
    
    PWActionHandler copyBlock = ^(PWAction *action) {
        [self copyPhotosToCameraRoll:photoCollectionView.indexPathsForSelectedItems];
    };
    PWAction *copyAction = [PWAction actionWithTitle:@"Copy to gallery"
                                             handler:copyBlock];
    
    
    _actionSheet = [[PWActionSheet alloc] initWithTitle:@"Select an action"];
    [_actionSheet addActions:@[cancelAction, deleteAction, copyAction]];
    [_actionSheet showFromBarButtonItem:_exportItem
                               animated:YES];
}

    /// Called when we want to edit the collection view. Overridden so we can clear the selection when editing ends.
-(void) setEditing: (BOOL)editing {
    [super setEditing:editing];
        // On turning off the editing option, clear the selection.
    if(!editing) {
        for (NSIndexPath *path in photoCollectionView.indexPathsForSelectedItems) {
            [photoCollectionView deselectItemAtIndexPath:path animated:NO];
        }
    }
}

    /// Present a FullImageViewController in "View" mode showing the image at the given index path.
-(void) showImageAtIndexPath: (NSIndexPath*)indexPath {
    NSError *error;
    UIImage *image = [_photoStore imageAtIndex:indexPath.item error:&error];
    if (image) {
        PWFullImageViewController *imageViewController = [[PWFullImageViewController alloc] initWithImage:image
                                                                                              atIndexPath:indexPath
                                                                                                 delegate:self];
        [self.navigationController pushViewController:imageViewController animated:YES];
    } else {
        NSString *title = [NSString stringWithFormat:@"Error accessing image at index %ld", (long)indexPath.item];
        [error showAlertWithTitle:title parentViewController:self.parentViewController];
    }
}

    /// Event called when the view appears.
-(void) viewDidAppear: (BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"PhotoViewController viewDidAppear: self = %@", self);
        // If stereogram is set, we have just reappeared from under the camera controller, and we need to pop up an approval window for the user to accept the new stereogram.
    if(_stereogram) {
        [self showApprovalWindowForImage:_stereogram];
        _stereogram = nil;
    }
}

    /// Display the FullImageViewController in "Approval" mode (which adds "Keep" and "Delete" buttons).
-(void) showApprovalWindowForImage: (UIImage*)image {
    PWFullImageViewController *imageViewController = [[PWFullImageViewController alloc] initWithImage:image
                                                                                          forApproval:YES
                                                                                             delegate:self];
    UINavigationController *navC = [[UINavigationController alloc] initWithRootViewController:imageViewController];
    navC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:navC animated:YES completion:nil];
}

    /// Return a potted description of the object.
- (NSString *)description {
    NSString *superDescription = [super description];
    NSString *desc = [NSString stringWithFormat:@"%@ <_photoStore = %@>", superDescription, _photoStore];
    return desc;
}

#pragma mark FullImageViewController delegate

-(void) fullImageViewController: (PWFullImageViewController *)controller
                  approvedImage: (UIImage *)image {
    NSError *error = nil;
    NSDate *dateTaken = [NSDate date];
    if (![_photoStore addImage:image dateTaken:dateTaken error:&error]) {
        [error showAlertWithTitle:@"Error saving photo" parentViewController:controller];
    }
    [photoCollectionView reloadData];
}

-(void) dismissedFullImageViewController: (PWFullImageViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark ImagePicker delegate

static UIImage *makeStereogram(PWPhotoStore *photoStore, UIImage *firstPhoto, UIImage *secondPhoto) {
    UIImage *stereogram = [ImageManager makeStereogramWithLeftPhoto:firstPhoto
                                                         rightPhoto:secondPhoto];
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

#pragma mark UICollectionView delegate

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

#pragma mark Private methods


-(void) copyPhotosToCameraRoll: (NSArray *)selectedIndexes {
    NSError *error = nil;
    for(NSIndexPath *indexPath in selectedIndexes) {
        if (![_photoStore copyImageToCameraRoll:[indexPath indexAtPosition:1]
                                          error:&error]) {
            [error showAlertWithTitle:@"Error exporting to camera roll" parentViewController:self];
            return; // Only show one error, don't force the user to keep OKing the error warning.
        }
    }
    [self setEditing:NO animated:YES];
}

-(void) showActivityIndicator: (BOOL)showIndicator {
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
    NSArray *selectedItems = [photoCollectionView.indexPathsForSelectedItems copy];
    
        // Convert the image in a background thread (it can take a while), showing a progress wheel to the user.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        for (NSIndexPath *indexPath in selectedItems) {
            NSAssert([indexPath indexAtPosition:0] == 0, @"Index Path %@ not for section 0", indexPath);
            NSError *error = nil;
            UIImage *image = [_photoStore imageAtIndex:[indexPath indexAtPosition:1] error:&error];
            if (![ImageManager changeViewingMethod:image]) {    // Index path has format [<section>, <item>].
                dispatch_async(dispatch_get_main_queue(), ^{
                    [error showAlertWithTitle:@"Error changing viewing method" parentViewController:self.parentViewController];
                    [self showActivityIndicator:NO];
                });
                return; // Exit to avoid showing the user multiple errors
            }
        }
            // Back on the main thread, deselect all the selected thumbnails, and stop the activity timer.
        dispatch_async(dispatch_get_main_queue(), ^{
            for(NSIndexPath *indexPath in selectedItems) {
                [photoCollectionView deselectItemAtIndexPath:indexPath animated:YES];
            }
            [self showActivityIndicator:NO];
            [photoCollectionView reloadItemsAtIndexPaths:selectedItems];
        });
    });
}

-(void) deletePhotos:(UICollectionView *)photoCollection {
    NSArray *indexPaths = [photoCollection indexPathsForSelectedItems];
    if(indexPaths.count > 0) {
        
        NSString *message = formatDeleteMessage(indexPaths.count);
        _alertView = [PWAlertView alertViewWithTitle:@"Confirm deletion"
                                             message:message
                                      preferredStyle:UIAlertControllerStyleAlert];
        
        PWAlertHandler deleteActionBlock = ^(PWAlertAction *action) {
            NSLog(@"Deleting images at index paths: %@", indexPaths);
            NSError *error = nil;
            if (![self.photoStore deleteImagesAtIndexPaths:indexPaths error:&error]) {
                [error showAlertWithTitle:@"Error deleting photos"
                     parentViewController:self];
            }
            [self setEditing:NO animated:YES];
            [photoCollection reloadData];
        };
        
        PWAlertAction *deleteAction = [PWAlertAction actionWithTitle:@"Delete"
                                                               style:UIAlertActionStyleDestructive
                                                             handler:deleteActionBlock];
        [_alertView addAction:deleteAction];
        [_alertView addAction:[PWAlertAction cancelAction]];
        
        [_alertView show];
    }
}

@end

static inline UIImage *imageFromPickerInfoDict(NSDictionary *infoDict) {
    UIImage *photo =       infoDict[UIImagePickerControllerEditedImage];
    return photo ? photo : infoDict[UIImagePickerControllerOriginalImage];
}

static NSString *formatDeleteMessage(NSUInteger numToDelete) {
    NSString * const postscript = @"This operation cannot be undone.";
    return numToDelete == 1 ? [NSString stringWithFormat:@"Do you really want to delete this photo?\n%@", postscript]
    : [NSString stringWithFormat:@"Do you really want to delete these %lu photos?\n%@", (unsigned long)numToDelete, postscript];
}

static inline UICollectionViewFlowLayout* cast_UICollectionViewFlowLayout(id layout) {
    NSCAssert([layout isKindOfClass:[UICollectionViewFlowLayout class]], @"Photo collection layout is not a flow layout");
    return (UICollectionViewFlowLayout *)layout;
}

