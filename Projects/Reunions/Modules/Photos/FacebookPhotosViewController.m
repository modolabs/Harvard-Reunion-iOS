#import "FacebookPhotosViewController.h"
#import "MediaContainerView.h"
#import "Foundation+KGOAdditions.h"
#import "FacebookModel.h"
#import <QuartzCore/QuartzCore.h>
#import "CoreDataManager.h"
#import "ReunionHomeModule.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "PhotoUploadViewController.h"
#import "PhotosModule.h"
#import "FacebookModule.h"
#import "KGOTheme.h"
#import "FacebookThumbnail.h"
#import "KGOSegmentedControl.h"
#import "KGOToolbar.h"

@interface FacebookPhotosViewController (Private)

- (FacebookPhotoSize)thumbSize;

- (NSDictionary *)paramsForPhotoDetails:(FacebookPhoto *)photo;
- (void)focusThumbnail:(FacebookThumbnail *)thumbnail animated:(BOOL)animated completion:(void (^)(BOOL finished))completion;
- (void)updateIconGrid;
- (void)showUploadPhotoController:(UIImagePickerControllerSourceType)sourceType;

@end



static NSString * const TakePhotoOption = @"Take a picture";
static NSString * const FromLibraryOption = @"From photo library";

@implementation FacebookPhotosViewController

@synthesize currentFilterBlock;
@synthesize photoPickerPopover;

// This method does not hit the API to get new photos. It expects _photosByID 
// to have the unfiltered collection of photos and applies filters locally 
// by means of displayPhoto:.
- (void)refreshPhotos {
    // Clear loaded photos and icons.
    [_displayedPhotos removeAllObjects];
    [_icons removeAllObjects];
    
    for (NSString *photoID in _photosByID) {
        FacebookPhoto *photo = [_photosByID objectForKey:photoID];
        [self displayPhoto:photo];
    }
    
    [self updateIconGrid];
}

- (void)getGroupPhotos {
    [[NSNotificationCenter defaultCenter] 
     removeObserver:self name:FacebookGroupReceivedNotification object:nil];
    [[NSNotificationCenter defaultCenter] 
     removeObserver:self name:FacebookFeedDidUpdateNotification object:nil];
    
    FacebookModule *fbModule = 
    (FacebookModule *)[KGO_SHARED_APP_DELEGATE() moduleForTag:@"facebook"];
    
    if (fbModule.groupID) {
        KGOAppDelegate *appDelegate = KGO_SHARED_APP_DELEGATE();
        ReunionHomeModule *homeModule = (ReunionHomeModule *)[appDelegate moduleForTag:@"home"];
        
        if ([homeModule fbGroupIsOld]) {
            // fql for photos
            NSString *query = [NSString stringWithFormat:@"SELECT pid, object_id FROM photo WHERE pid IN (SELECT pid FROM photo_tag WHERE subject = %@ LIMIT 1000) LIMIT 1000", fbModule.groupID];
            [[KGOSocialMediaController facebookService] requestFacebookFQL:query 
                                                                  receiver:self 
                                                                  callback:@selector(didReceivePhotoList:)];

        } else {
            if (fbModule.latestFeedPosts && (fbModule.latestFeedPosts.count > 0)) {

                for (NSDictionary *aPost in fbModule.latestFeedPosts) {
                    NSString *type = [aPost stringForKey:@"type" nilIfEmpty:YES];
                    if ([type isEqualToString:@"photo"]) {
                        NSString *pid = [aPost stringForKey:@"object_id" nilIfEmpty:YES];
                        if (pid && ![_photosByID objectForKey:pid]) {
                            FacebookPhoto *aPhoto = [FacebookPhoto photoWithDictionary:aPost size:[self thumbSize]];
                            if (aPhoto) {
                                aPhoto.postIdentifier = 
                                [aPost stringForKey:@"id" nilIfEmpty:YES];
                                NSLog(@"%@", [aPhoto description]);
                                [[CoreDataManager sharedManager] saveData];
                                [_photosByID setObject:aPhoto forKey:pid];
                            }
                            DLog(@"requesting graph info for photo %@", pid);
                            [[KGOSocialMediaController facebookService] requestFacebookGraphPath:pid
                                                                                        receiver:self
                                                                                        callback:@selector(didReceivePhoto:)];
                        }
                    }
                }            
                [self refreshPhotos];
            } 
            else {
                // Sometimes the photos FB request will come back right away with no 
                // photos. We need to make the request a few more times until we get
                // something back or give up after 5 attempts (with a 3-second delay 
                // between each).
                dispatch_block_t photosRequestBlock = 
                ^{
                    [[NSNotificationCenter defaultCenter] 
                     addObserver:self 
                     selector:@selector(getGroupPhotos)
                     name:FacebookFeedDidUpdateNotification
                     object:nil];
                    [fbModule requestStatusUpdates:nil];
                };
                if (_photosRequestCount > 0) {
                    dispatch_after(NSEC_PER_SEC * 3, dispatch_get_current_queue(),
                                   photosRequestBlock);
                }
                else {
                    if (_photosRequestCount < 6) {
                        photosRequestBlock();
                        ++_photosRequestCount;
                    }
                }

            }
        }

    } else {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(getGroupPhotos)
                                                     name:FacebookGroupReceivedNotification
                                                   object:nil];
    }
}

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

- (void)loadView
{
    [super loadView];

    // old style groups cannot take photo uploads via the graph API afaik
    KGOAppDelegate *appDelegate = KGO_SHARED_APP_DELEGATE();
    ReunionHomeModule *homeModule = (ReunionHomeModule *)[appDelegate moduleForTag:@"home"];
    if ([homeModule fbGroupIsOld] && [self.subheadToolbar.items containsObject:_uploadButton]) {
        NSMutableArray *array = [[self.subheadToolbar.items mutableCopy] autorelease];
        [array removeObject:_uploadButton];
        self.subheadToolbar.items = [NSArray arrayWithArray:array];
    }
    
    [_filterControl insertSegmentWithTitle:@"All Photos" atIndex:0 animated:NO];
    [_filterControl insertSegmentWithTitle:@"My Photos" atIndex:1 animated:NO];
    [_filterControl insertSegmentWithTitle:@"Bookmarks" atIndex:2 animated:NO];
    
    _filterControl.selectedSegmentIndex = 0;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Photos";
    
    CGRect frame = _scrollView.frame;
    frame.origin.x += 6.0f; // This will make the iconGrid appear centered.
    frame.origin.y = 0;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        resizeFactor = 1.;
    } else {
        resizeFactor = 1.9;
    }
    CGFloat spacing = 10. * resizeFactor;
    
    _iconGrid = [[IconGrid alloc] initWithFrame:frame];
    _iconGrid.topPadding = 0;
    _iconGrid.delegate = self;
    _iconGrid.spacing = GridSpacingMake(spacing, spacing);
    _iconGrid.padding = GridPaddingMake(spacing, spacing, spacing, spacing);
    _iconGrid.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _iconGrid.backgroundColor = [UIColor clearColor];
    
    [_scrollView addSubview:_iconGrid];
    
    _icons = [[NSMutableArray alloc] init];
    _photosByID = [[NSMutableDictionary alloc] init];
    _displayedPhotos = [[NSMutableSet alloc] init];
}

- (void)facebookDidLogin:(NSNotification *)aNotification
{
    [super facebookDidLogin:aNotification];
    
    [self loadThumbnailsFromCache];
    [self getGroupPhotos];
    
    self.navigationItem.rightBarButtonItem = 
    [[[UIBarButtonItem alloc] 
      initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
      target:self
      action:@selector(uploadButtonPressed:)] autorelease];
}

- (void)facebookDidLogout:(NSNotification *)aNotification
{
    [super facebookDidLogout:aNotification];
    
    self.navigationItem.rightBarButtonItem = nil;
    
    _iconGrid.icons = nil;
    [_iconGrid setNeedsLayout];
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [_detailViewController release];
    _detailViewController = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshPhotos];
}

- (void)dealloc {
    [[KGOSocialMediaController facebookService] disconnectFacebookRequests:self];

    [currentFilterBlock release];
    [_iconGrid release];
    [_icons release];
    [_displayedPhotos release];
    [_photosByID release];
    [super dealloc];
}

#pragma Icon grid delegate

- (void)iconGridFrameDidChange:(IconGrid *)iconGrid {
    CGSize size = _scrollView.contentSize;
    size.height = iconGrid.frame.size.height;
    _scrollView.contentSize = size;
}

#pragma mark When we already have photos

- (void)loadThumbnailsFromCache {
    // TODO: sort by date or whatever
    NSArray *photos = [[CoreDataManager sharedManager] objectsForEntity:FacebookPhotoEntityName matchingPredicate:nil];
    for (FacebookPhoto *aPhoto in photos) {
        [_photosByID setObject:aPhoto forKey:aPhoto.identifier];
        NSLog(@"found cached photo %@", aPhoto.identifier);
        [self displayPhoto:aPhoto];
    }
    [self updateIconGrid];

    //[[CoreDataManager sharedManager] deleteObjects:photos];
}

- (void)displayPhoto:(FacebookPhoto *)photo
{    
    // If there's a filter set, and this photos doesn't pass it, don't add it.
    if (self.currentFilterBlock && (!self.currentFilterBlock(photo))) {
        return;
    }
    
    if ([_displayedPhotos containsObject:photo.identifier]) {
        return;
    }
    
    if (photo.thumbSrc || photo.thumbData || photo.data) { // omitting photo.src so we don't download full image until detail view
        CGRect frame = CGRectMake(0, 0, 90 * resizeFactor, 90 * resizeFactor + 20);
        
        FacebookThumbnail *thumbnail = 
        [[[FacebookThumbnail alloc] initWithFrame:frame displayLabels:NO] autorelease];
        thumbnail.thumbSource = photo;
        thumbnail.rotationAngle = (_icons.count % 2 == 0) ? M_PI/30 : -M_PI/30;
        [thumbnail addTarget:self action:@selector(thumbnailTapped:) forControlEvents:UIControlEventTouchUpInside];
        [_icons addObject:thumbnail];
        _iconGrid.icons = _icons;
        
        [_displayedPhotos addObject:photo.identifier];
    }
}

- (void)thumbnailTapped:(FacebookThumbnail *)sender {
    FacebookPhoto *photo = (FacebookPhoto *)sender.thumbSource;
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        NSDictionary *params = [self paramsForPhotoDetails:photo];
        [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameDetail forModuleTag:PhotosTag params:params];
    } else {
        [self focusThumbnail:sender animated:YES completion:^(BOOL finished) {
            NSDictionary *params = [self paramsForPhotoDetails:photo];
            [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameDetail forModuleTag:PhotosTag params:params];
        }];
    }
}

- (void)focusThumbnail:(FacebookThumbnail *)thumbnail animated:(BOOL)animated completion:(void (^)(BOOL finished))completion {
    _scrollView.scrollEnabled = NO;
    NSTimeInterval duration = animated ? 0.75 : -1.0;
    [UIView animateWithDuration:duration animations:^{
        for (FacebookThumbnail *icon in _icons) {
            if (icon != thumbnail) {
                [icon hide];
            }
        }
        // this frame is designed to match the frame for image in the
        // detailed view
        FacebookPhoto *photo = (FacebookPhoto *)thumbnail.thumbSource;
        CGSize imageSize = 
        CGSizeMake([photo.width floatValue], [photo.height floatValue]);
        CGFloat maximumWidth = self.view.frame.size.width - 40;
        CGFloat height = [MediaContainerView heightForImageSize:imageSize 
                                                     fitToWidth:maximumWidth
                                                    maxHeight:[MediaContainerView defaultMaxHeight]];
        [thumbnail highlightIntoFrame:CGRectMake(15, _scrollView.contentOffset.y + 15, 
                                                maximumWidth, height)];
        
    } completion:completion];
}

- (void)updateIconGrid {
    _iconGrid.icons = _icons;
    [_iconGrid setNeedsLayout];
}

- (NSDictionary *)paramsForPhotoDetails:(FacebookPhoto *)photo {
    NSMutableArray *photos = [NSMutableArray array];
    [_icons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        FacebookThumbnail *thumbnail = (FacebookThumbnail *)obj;
        FacebookPhoto *photo = (FacebookPhoto *)thumbnail.thumbSource;
        NSLog(@"adding photo with id %@", photo.identifier);
        [photos addObject:photo];
    }];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:photo, @"photo", photos, @"photos", nil];
    return params;
}

#pragma mark Photo uploads

- (void)uploadDidComplete:(FacebookPost *)result {
    [self dismissModalViewControllerAnimated:YES];    
    self.photoPickerPopover = nil;
    
    FacebookPhoto *photo = (FacebookPhoto *)result;
    [_photosByID setObject:photo forKey:photo.identifier];
    
    [[KGOSocialMediaController facebookService] requestFacebookGraphPath:photo.identifier
                                                                receiver:self
                                                                callback:@selector(didReceivePhoto:)];    
    [self displayPhoto:photo];
    [self updateIconGrid];
}

// TODO: this needs to be implemented upstream by the facebook controller
- (void)uploadDidFail
{
    [self dismissModalViewControllerAnimated:YES];    
    self.photoPickerPopover = nil;
    
    UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Oops!"
                                                         message:@"Could not upload your photo, please try again later."
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil] autorelease];
    [alertView show];
}

#pragma mark Facebook request callbacks

- (void)didReceivePhotoList:(id)result {
    
    if ([result isKindOfClass:[NSArray class]]) {
        
        for (NSDictionary *info in result) {
            NSString *pid = [info objectForKey:@"pid"];
            NSString *objectId = [NSString stringWithFormat:@"%@", [info objectForKey:@"object_id"], nil];
            if (pid && ![_photosByID objectForKey:pid]) {
                FacebookPhoto *aPhoto = [FacebookPhoto photoWithDictionary:info size:[self thumbSize]];
                if (aPhoto) {
                    aPhoto.postIdentifier = objectId;
                    NSLog(@"%@", [aPhoto description]);
                    [[CoreDataManager sharedManager] saveData];
                    [_photosByID setObject:aPhoto forKey:pid];
                }
                DLog(@"requesting graph info for photo %@", pid);
                [[KGOSocialMediaController facebookService] requestFacebookGraphPath:objectId
                                                                            receiver:self
                                                                            callback:@selector(didReceivePhoto:)];
            }
        }
    }
}

- (void)didReceivePhoto:(id)result {
    DLog(@"info for photo: %@", [result description]);
    
    NSDictionary *photoInfo = nil;
    
    // TODO: check these requests against their origin rather than just checking type
    if ([result isKindOfClass:[NSDictionary class]]) {
        photoInfo = (NSDictionary *)result;
        
    } else if ([result isKindOfClass:[NSArray class]]) {
        // request came from fql
        photoInfo = [result lastObject];
    }
    
    NSString * identifier = [photoInfo objectForKey:@"object_id"]; // via feed or FQL
    if (!identifier) {
        identifier = [photoInfo objectForKey:@"id"]; // via Photo Graph API
    }
    identifier = [NSString stringWithFormat:@"%@", identifier];
    
    FacebookPhoto *photo = [_photosByID objectForKey:identifier];
    
    if (photo) {
        [photo updateWithDictionary:photoInfo size:[self thumbSize]];
        [self displayPhoto:photo];
        [self updateIconGrid];
        
    } else {
        photo = [FacebookPhoto photoWithDictionary:photoInfo size:[self thumbSize]];
        if (photo) {
            [_photosByID setObject:photo forKey:photo.identifier];
            [self displayPhoto:photo];
            [self updateIconGrid];
        }
    }
}

- (FacebookPhotoSize)thumbSize {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        return TINY;
    } else {
        return MEDIUM;
    }
}

#pragma mark FacebookMediaViewController
- (IBAction)uploadButtonPressed:(id)sender {
    // there are actually three source type options, and if there was more time
    // we would ideally check all of them for whether they are available
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIActionSheet *sheet = [[[UIActionSheet alloc] initWithTitle:@"Upload Photo"
                                                            delegate:self
                                                   cancelButtonTitle:nil
                                              destructiveButtonTitle:nil
                                                   otherButtonTitles:TakePhotoOption, FromLibraryOption, nil] autorelease];
        [sheet showInView:self.view];
        
    } else {
        [self showUploadPhotoController:UIImagePickerControllerSourceTypePhotoLibrary];
    }
}
     
- (void)imagePickerController:(UIImagePickerController *)picker 
didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];    
    FacebookModule *fbModule = 
    (FacebookModule *)[KGO_SHARED_APP_DELEGATE() moduleForTag:@"facebook"];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            image, @"photo",
                            fbModule.groupID, @"profile",
                            self, @"parentVC",
                            nil];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        PhotosModule *photosModule = 
        (PhotosModule *)[KGO_SHARED_APP_DELEGATE() moduleForTag:PhotosTag];
        UIViewController *vc = 
        [photosModule modulePage:LocalPathPageNamePhotoUpload params:params];
        vc.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentModalViewController:vc animated:YES];
    }
    else {
        [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNamePhotoUpload
                               forModuleTag:PhotosTag
                                     params:params];
    }

    // doing this doesn't call the popover delegate methods,
    // so we assign self.photoPickerPopover to nil when the upload terminates.
    [self.photoPickerPopover dismissPopoverAnimated:YES];
}

- (IBAction)filterValueChanged:(UISegmentedControl *)sender {

    switch (sender.selectedSegmentIndex) {
        case kAllMediaObjectsSegment:
        {
            // Reload photos.
            self.currentFilterBlock = nil;
            [self refreshPhotos];
            break;
        }
        case kMyUploadsSegment:
        {
            NSString *uploaderIdentifier = 
            [[[KGOSocialMediaController facebookService] currentFacebookUser]
             identifier];
            
            self.currentFilterBlock =
            [[
              ^(FacebookPhoto *photo) {
                  NSString *photoOwner = [[photo owner] identifier];
                  return [photoOwner isEqualToString:uploaderIdentifier];
              } 
              copy] autorelease];
            
            [self refreshPhotos];
            break;
        }
        case kBookmarksSegment:
        {            
            self.currentFilterBlock =
            [[
              ^(FacebookPhoto *photo) {
                  return [FacebookModule 
                          isMediaObjectWithIDBookmarked:photo.identifier 
                          mediaType:@"photo"];
              } 
              copy] autorelease];
            
            [self refreshPhotos];            
            break;
        }
        default:
            break;
    } 
}

#pragma mark Photo upload

- (void)showUploadPhotoController:(UIImagePickerControllerSourceType)sourceType
{
    UIImagePickerController *picker = 
    [[[UIImagePickerController alloc] init] autorelease];
    picker.delegate = self;
    
    picker.sourceType = sourceType;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // Show the popover if it is not already there.
        if (!self.photoPickerPopover) {
            self.photoPickerPopover = 
            [[[UIPopoverController alloc] initWithContentViewController:picker] 
             autorelease];
            self.photoPickerPopover.delegate = self;
            [self.photoPickerPopover 
             presentPopoverFromBarButtonItem:_uploadButton
             permittedArrowDirections:UIPopoverArrowDirectionAny 
             animated:YES];
        }
    }
    else {
        [self presentModalViewController:picker animated:YES];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([title isEqualToString:TakePhotoOption]) {
        [self showUploadPhotoController:UIImagePickerControllerSourceTypeCamera];
    } else {
        [self showUploadPhotoController:UIImagePickerControllerSourceTypePhotoLibrary];
    }
}

#pragma mark UIPopoverControllerDelegate
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    self.photoPickerPopover = nil;
}

@end
