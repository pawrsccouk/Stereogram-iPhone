//
//  PhotoViewController.m
//  Stereogram
//
//  Created by Patrick Wallace on 20/01/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#import "PhotoViewController.h"
#import "PhotoStore.h"
#import "NSError_AlertSupport.h"
#import "UIImage+Resize.h"
#import "ImageThumbnailCell.h"
#import "FullImageViewController.h"
#import "PWAlertView.h"
#import "PWActionSheet.h"
#import "NSError_AlertSupport.h"
#import "ErrorData.h"
#import "ImageManager.h"
#import "CollectionViewThumbnailProvider.h"
#import "Stereogram.h"
#import "PWFunctional.h"

static NSString *const IMAGE_THUMBNAIL_CELL_ID = @"CollectionViewCell_Thumbnail";

static NSString *formatDeleteMessage(NSUInteger numToDelete) {
    NSString * const postscript = @"This operation cannot be undone.";
    return numToDelete == 1 ? [NSString stringWithFormat:@"Do you really want to delete this photo?\n%@", postscript]
    : [NSString stringWithFormat:@"Do you really want to delete these %lu photos?\n%@", (unsigned long)numToDelete, postscript];
}

static inline UICollectionViewFlowLayout* cast_UICollectionViewFlowLayout(id layout) {
    NSCAssert([layout isKindOfClass:[UICollectionViewFlowLayout class]], @"Photo collection layout is not a flow layout");
    return (UICollectionViewFlowLayout *)layout;
}

/*! HTML text to use as an email body.
 *
 * Contains two replaceable parameters:
 *
 * #. Text to use for the main body. Example: "Here are 2 images exported from Stereogram"
 * #. A date on which they were exported.
 */
static NSString *emailBodyTemplate =
    @"<html>"
    @"  <head/>"
    @"  <body>"
    @"    <H1>Exported Stereograms</H1>"
    @"    <p>%@<br/>"
    @"       Exported on %@"
    @"    </p>"
    @"  </body>"
    @"</html>";


#pragma mark - 

@interface PhotoViewController () {
    UIBarButtonItem *_exportItem, *_editItem;
    UIActivityIndicatorView *_activityIndicator;
    CollectionViewThumbnailProvider *_thumbnailProvider;
    StereogramViewController *_stereogramViewController;
    PWAlertView *_alertView;
    PWActionSheet *_actionSheet;
}
@end

@implementation PhotoViewController
@synthesize photoStore = _photoStore, photoCollectionView = _photoCollectionView;

#pragma mark Housekeeping

-(instancetype) initWithPhotoStore: (PhotoStore *)photoStore {
    self = [super initWithNibName:@"PhotoView" bundle:nil];
    if (self) {
        _photoStore = photoStore;
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

#pragma mark Overrides

- (void) viewDidLoad {
    [super viewDidLoad];
    
    [self.self.photoCollectionView registerClass:[ImageThumbnailCell class] forCellWithReuseIdentifier:IMAGE_THUMBNAIL_CELL_ID];
    self.photoCollectionView.allowsSelection = YES;
    self.photoCollectionView.allowsMultipleSelection = YES;
    
        // Set the thumbnail size from the store.
    UICollectionViewFlowLayout *flowLayout = cast_UICollectionViewFlowLayout(self.photoCollectionView.collectionViewLayout);
    flowLayout.itemSize = [Stereogram thumbnailSize];
    [flowLayout invalidateLayout];

        // Pass a provider to copy data from the model to the collection view.
    _thumbnailProvider = [[CollectionViewThumbnailProvider alloc] initWithPhotoStore:_photoStore
                                                                          collection:self.photoCollectionView];
}

    /// Return a potted description of the object.
- (NSString *)description {
    NSString *superDescription = [super description];
    NSString *desc = [NSString stringWithFormat:@"%@ <_photoStore = %@>", superDescription, _photoStore];
    return desc;
}

    /// Called when we want to edit the collection view. Overridden so we can clear the selection when editing ends.
-(void) setEditing: (BOOL)editing {
    [super setEditing:editing];
        // On turning off the editing option, clear the selection.
    if (!editing) {
        for (NSIndexPath *path in self.photoCollectionView.indexPathsForSelectedItems) {
            [self.photoCollectionView deselectItemAtIndexPath:path animated:NO];
        }
    }
}

#pragma mark StereogramViewController delegate

-(void) stereogramViewController: (StereogramViewController *)controller
               createdStereogram: (Stereogram *)stereogram {
    [controller dismissViewControllerAnimated:YES
                                      completion: ^{
                                              // Once dismissed, trigger the full image view controller to examine the image.
                                          [controller reset];
                                          [self showApprovalWindowForStereogram:stereogram];
                                      }];
}

-(void) stereogramViewControllerWasCancelled: (StereogramViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark FullImageViewController delegate

-(void) fullImageViewController: (FullImageViewController *)controller
            approvingStereogram: (Stereogram *)stereogram
                         result: (ApprovalResults)result {
        // If the user discards the stereogram, then delete it from the disk and from the collection.
    if (result == ApprovalResult_Discarded) {
        NSError *error = nil;
        if (![_photoStore deleteStereogram:stereogram
                                     error:&error]) {
            [error showAlertWithTitle:@"Error discarding stereogram"
                 parentViewController:self];
        }
    }
    [self.photoCollectionView reloadData];
}

-(void) dismissedFullImageViewController: (FullImageViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:nil];
}


-(void) fullImageViewController: (FullImageViewController *)controller
              amendedStereogram: (Stereogram *)newStereogram
                    atIndexPath: (NSIndexPath *)indexPath {
        // If indexPath is nil, we are calling it in approval mode and the image doesn't exist in the library yet. In which case, don't do anything, as we will handle it in the approvedImage delegate method.
        // If indexPath is valid, we are updating an existing entry. So replace the image at the path with the new image provided.
    if (indexPath) {
        NSError *error = nil;
        if (![self.photoStore replaceStereogramAtIndex:indexPath.item
                                        withStereogram:newStereogram
                                                 error:&error]) {
            [error showAlertWithTitle:@"Stereogram update error"
                 parentViewController:controller];
        }
        [_photoCollectionView reloadItemsAtIndexPaths:@[indexPath]];
    }
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

#pragma mark MFMailComposeViewController delegate

-(void) mailComposeController: (MFMailComposeViewController *)controller
          didFinishWithResult: (MFMailComposeResult)result
                        error: (NSError *)error {
        // Dismiss the view controller window, and if there was an error display it after the main view has been removed.
    [self dismissViewControllerAnimated:YES completion: ^{
        if (result == MFMailComposeResultFailed) {
            NSError *err = error ? error : [NSError unknownErrorWithLocation:@"MFMailComposeViewController"];
            [err showAlertWithTitle: @"Error sending mail" parentViewController: self];
        }
    }];
    
}

#pragma mark Private methods

    /// Kick off the picture-taking process. Present the camera view controller with our custom overlay on top.
-(void) takePicture {
    _stereogramViewController = [[StereogramViewController alloc] initWithPhotoStore:self.photoStore
                                                                            delegate:self];
    [_stereogramViewController takePicture:self];
}

    /// Create and display an action menu with the items available for a set of the collection items.
-(void) actionMenu {
    if (self.photoCollectionView.indexPathsForSelectedItems.count == 0) {
        return; // Do nothing if there are no items to act on.
    }
    
    _actionSheet = [[PWActionSheet alloc] initWithTitle:@"Action"];
    
    PWAction *cancelAction = [PWAction cancelAction];
    
    PWActionHandler deleteBlock = ^(PWAction *action) {
        [self deletePhotos:self.photoCollectionView];
    };
    PWAction *deleteAction = [PWAction actionWithTitle:@"Delete"
                                                 style:UIAlertActionStyleDestructive
                                               handler:deleteBlock];
    
    
    PWActionHandler copyBlock = ^(PWAction *action) {
        [self copyPhotosToCameraRoll:self.photoCollectionView.indexPathsForSelectedItems];
    };
    PWAction *copyAction = [PWAction actionWithTitle:@"Copy to gallery"
                                             handler:copyBlock];
    
    PWActionHandler emailBlock = ^(PWAction *action) {
        [self sendPhotosViaEmail:self.photoCollectionView.indexPathsForSelectedItems];
    };
    PWAction *emailAction = [PWAction actionWithTitle:@"Email"
                                              handler:emailBlock];
    [_actionSheet addActions:@[cancelAction, deleteAction, copyAction, emailAction]];
    [_actionSheet showFromBarButtonItem:_exportItem
                               animated:YES];
}

-(void) sendPhotosViaEmail: (NSArray *)indexPaths {
        /// Present an email message with the selected stereograms attached.
        ///
        /// :param: selectedIndexes - An array of NSIndexPath objects identifying stereograms in the photo store which we want to export.
    
    
            // Abort if there are no email accounts on this device.
        if (![MFMailComposeViewController canSendMail]) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"This device is not set up to send email."};
            NSError *error = [[NSError alloc] initWithDomain: kErrorDomainPhotoStore
                                                        code: ErrorCode_FeatureUnavailable
                                                    userInfo: userInfo];
            [error showAlertWithTitle:@"Export via email"
                 parentViewController: self];
            return;
        }
        
            // Find all the stereograms we requested for export.
    NSError *error = nil;
    Stereogram *failedStereogram = nil;
    NSMutableArray *allImages = [NSMutableArray array];
    NSArray *stereograms = [indexPaths transformedArrayUsingBlock:^Stereogram *(NSIndexPath *object) {
        return [_photoStore stereogramAtIndex:[object indexAtPosition:1]];
    }];
    for (Stereogram *stereogram in stereograms) {
        NSString *mimeType = nil;
        NSData *exportData = [stereogram exportDataWithMimeType:&mimeType error:&error];
        if (!exportData) {
            failedStereogram = stereogram;
            break; // Exit the loop on the first error.
        }
        [allImages addObject:@[exportData, mimeType]];
     }
    
    if (failedStereogram) {
        error = error ? error : [NSError unknownErrorWithCaller: @"sendPhotosViaEmail:"
                                                         target: failedStereogram
                                                         method: @selector(exportDataWithMimeType:error:)];
        [error showAlertWithTitle: @"Error exporting to email" parentViewController: self];
        return;
    }
        
            // Present a mail compose view with the images as attachments.
        
    MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
    mailVC.mailComposeDelegate = self;
    mailVC.subject = @"Exported Stereograms.";
    NSString *mainText = (stereograms.count != 1
                          ? [NSString stringWithFormat: @"Here are %d images exported from Stereogram.", stereograms.count]
                          : @"Here is an image exported from Stereogram.");
    NSString *bodyText = [NSString stringWithFormat: emailBodyTemplate, mainText, [NSDate date].description];
    [mailVC setMessageBody:bodyText isHTML:YES];
    
    NSUInteger index = 1;
    for (NSArray *stereogramData in allImages) {
        NSString *fileName = [NSString stringWithFormat:@"Image%d", index++];
        [mailVC addAttachmentData:stereogramData[0]
                         mimeType:stereogramData[1]
                         fileName:fileName];
    }
    [self presentViewController:mailVC
                       animated:YES
                     completion:nil];
    
            // Now stop editing, which will deselect all the items.
    [self setEditing:NO animated:YES];
}


    /// Present a FullImageViewController in "View" mode showing the image at the given index path.
-(void) showImageAtIndexPath: (NSIndexPath*)indexPath {
    Stereogram *stereogram = [_photoStore stereogramAtIndex:indexPath.item];
    NSAssert(stereogram, @"No stereogram at index path %@", indexPath);
    if (stereogram) {
        FullImageViewController *imageViewController = [[FullImageViewController alloc] initWithStereogram:stereogram
                                                                                               atIndexPath:indexPath
                                                                                                  delegate:self];
        [self.navigationController pushViewController:imageViewController animated:YES];
    } else {
        NSLog(@"Error accessing image at index %ld", (long)indexPath.item);
    }
}


    /// Display the FullImageViewController in "Approval" mode (which adds "Keep" and "Delete" buttons).
-(void) showApprovalWindowForStereogram: (Stereogram *)stereogram {
    FullImageViewController *imageViewController = [[FullImageViewController alloc] initWithStereogram:stereogram
                                                                                           forApproval:YES
                                                                                              delegate:self];
    UINavigationController *navC = [[UINavigationController alloc] initWithRootViewController:imageViewController];
    navC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:navC animated:YES completion:nil];
}



-(void) copyPhotosToCameraRoll: (NSArray *)selectedIndexes {
    NSError *error = nil;
    for(NSIndexPath *indexPath in selectedIndexes) {
        if (![_photoStore copyStereogramToCameraRoll:[indexPath indexAtPosition:1]
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
    NSArray *selectedItems = [self.photoCollectionView.indexPathsForSelectedItems copy];
    
        // Convert the image in a background thread (it can take a while), showing a progress wheel to the user.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        for (NSIndexPath *indexPath in selectedItems) {
            NSAssert([indexPath indexAtPosition:0] == 0, @"Index Path %@ not for section 0", indexPath);
            Stereogram *stereogram = [_photoStore stereogramAtIndex:[indexPath indexAtPosition:1]];
            switch (stereogram.viewingMethod) {
                case ViewingMethod_CrossEye:
                    stereogram.viewingMethod = ViewingMethod_WallEye;
                    break;
                case ViewingMethod_WallEye:
                    stereogram.viewingMethod = ViewingMethod_CrossEye;
                    break;
                default:
                    [NSException raise:@"Not implemented"
                                format:@"Viewing method: %ld in stereogram %@ is not implemented.", (long)stereogram.viewingMethod, stereogram];
                    break;
            }
                // Refresh the stereogram now, in the background thread as updating the image can take a while. Once complete, further requests will use the cached image.
            NSError *error = nil;
            if (![stereogram refresh:&error]) {    // Index path has format [<section>, <item>].
                dispatch_async(dispatch_get_main_queue(), ^{
                    [error showAlertWithTitle:@"Error changing viewing method"
                         parentViewController:self.parentViewController];
                    [self showActivityIndicator:NO];
                });
                return; // Exit to avoid showing the user multiple errors
            }
        }
            // Back on the main thread, deselect all the selected thumbnails, and stop the activity timer.
        dispatch_async(dispatch_get_main_queue(), ^{
            for(NSIndexPath *indexPath in selectedItems) {
                [self.photoCollectionView deselectItemAtIndexPath:indexPath animated:YES];
            }
            [self showActivityIndicator:NO];
            [self.photoCollectionView reloadItemsAtIndexPaths:selectedItems];
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
        
        PWActionHandler deleteActionBlock = ^(PWAction *action) {
            NSLog(@"Deleting images at index paths: %@", indexPaths);
            NSError *error = nil;
            if (![self.photoStore deleteStereogramsAtIndexPaths:indexPaths
                                                          error:&error]) {
                [error showAlertWithTitle:@"Error deleting photos"
                     parentViewController:self];
            }
            [self setEditing:NO animated:YES];
            [photoCollection reloadData];
            _alertView = nil;
        };
        
        PWAction *deleteAction = [PWAction actionWithTitle:@"Delete"
                                                     style:UIAlertActionStyleDestructive
                                                   handler:deleteActionBlock];
        [_alertView addActions:@[deleteAction, [PWAction cancelAction]]];
        [_alertView show];
    }
}

@end

