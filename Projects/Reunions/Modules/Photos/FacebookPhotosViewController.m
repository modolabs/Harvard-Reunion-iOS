#import "FacebookPhotosViewController.h"
#import "MediaContainerView.h"
#import "Foundation+KGOAdditions.h"
#import "FacebookModel.h"
#import <QuartzCore/QuartzCore.h>
#import "CoreDataManager.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "PhotoUploadViewController.h"
#import "PhotosModule.h"
#import "FacebookModule.h"
#import "KGOTheme.h"
#import "FacebookThumbnail.h"

typedef enum {
    kAllPhotosSegment = 0,
    kMyUploadsSegment,
    kBookmarksSegment
}
FacebookPhotosSegmentIndexes;


@interface FacebookPhotosViewController (Private)

- (FacebookPhotoSize)thumbSize;

- (NSDictionary *)paramsForPhotoDetails:(FacebookPhoto *)photo;
- (void)focusThumbnail:(FacebookThumbnail *)thumbnail animated:(BOOL)animated completion:(void (^)(BOOL finished))completion;
- (void)updateIconGrid;

@end

@implementation FacebookPhotosViewController

@synthesize currentFilterBlock;

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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FacebookGroupReceivedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FacebookFeedDidUpdateNotification object:nil];
    
    FacebookModule *fbModule = (FacebookModule *)[KGO_SHARED_APP_DELEGATE() moduleForTag:@"facebook"];
    if (fbModule.groupID) {
        if (fbModule.latestFeedPosts) {

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
                        [[KGOSocialMediaController sharedController] requestFacebookGraphPath:pid
                                                                                     receiver:self
                                                                                     callback:@selector(didReceivePhoto:)];
                    }
                }
            }            
            [self refreshPhotos];
        } else {
            [fbModule requestStatusUpdates:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(getGroupPhotos)
                                                         name:FacebookFeedDidUpdateNotification
                                                       object:nil];
        }
        
        // fql for photos
        //NSString *query = [NSString stringWithFormat:@"SELECT pid FROM photo_tag WHERE subject=%@", fbModule.groupID];
        //[[KGOSocialMediaController sharedController] requestFacebookFQL:query receiver:self callback:@selector(didReceivePhotoList:)];

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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Photos";
    
    CGRect frame = _scrollView.frame;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        resizeFactor = 1.;
    } else {
        resizeFactor = 1.9;
    }
    CGFloat spacing = 10. * resizeFactor;
    
    _iconGrid = [[IconGrid alloc] initWithFrame:frame];
    _iconGrid.delegate = self;
    _iconGrid.spacing = GridSpacingMake(spacing, spacing);
    _iconGrid.padding = GridPaddingMake(spacing, spacing, spacing, spacing);
    _iconGrid.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _iconGrid.backgroundColor = [UIColor clearColor];
    
    [_scrollView addSubview:_iconGrid];
    
    _icons = [[NSMutableArray alloc] init];
    _photosByID = [[NSMutableDictionary alloc] init];
    _displayedPhotos = [[NSMutableSet alloc] init];
    
    [self loadThumbnailsFromCache];
    [self getGroupPhotos];
    
    self.navigationItem.rightBarButtonItem = 
    [[[UIBarButtonItem alloc] 
      initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
      target:self
      action:@selector(showUploadPhotoController:)] autorelease];
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


- (void)dealloc {
    [[KGOSocialMediaController sharedController] disconnectFacebookRequests:self];

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
        CGRect frame = CGRectMake(0, 0, 90 * resizeFactor, 90 * resizeFactor + 40);
        
        FacebookThumbnail *thumbnail = [[[FacebookThumbnail alloc] initWithFrame:frame] autorelease];
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
        CGFloat height = [MediaContainerView heightForImageSize:imageSize fitToWidth:maximumWidth];
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
    
    FacebookPhoto *photo = (FacebookPhoto *)result;
    [_photosByID setObject:photo forKey:photo.identifier];
    
    [[KGOSocialMediaController sharedController] requestFacebookGraphPath:photo.identifier
                                                                 receiver:self
                                                                 callback:@selector(didReceivePhoto:)];    
    [self displayPhoto:photo];
    [self updateIconGrid];
}

#pragma mark Facebook request callbacks

- (void)didReceivePhotoList:(id)result {
    
    if ([result isKindOfClass:[NSArray class]]) {
        
        for (NSDictionary *info in result) {
            NSString *pid = [info objectForKey:@"pid"];
            if (pid && ![_photosByID objectForKey:pid]) {
                DLog(@"received fql info for photo %@", pid);
                NSString *query = [NSString stringWithFormat:@"SELECT object_id, "
                                   "src_small, src_small_width, src_small_height, "
                                   "src, src_width, src_height, "
                                   "owner, caption, created, aid "
                                   "FROM photo WHERE pid=%@", pid];
                
                [[KGOSocialMediaController sharedController] requestFacebookFQL:query receiver:self callback:@selector(didReceivePhoto:)];
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
    [self showUploadPhotoController:sender];
}
     
- (void)imagePickerController:(UIImagePickerController *)picker 
didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [super imagePickerController:picker didFinishPickingMediaWithInfo:info];
    
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

    self.photoPickerPopover = nil;
}

- (IBAction)filterValueChanged:(UISegmentedControl *)sender {

    switch (sender.selectedSegmentIndex) {
        case kAllPhotosSegment:
        {
            // Reload photos.
            self.currentFilterBlock = nil;
            [self refreshPhotos];
            break;
        }
        case kMyUploadsSegment:
        {
            NSString *uploaderIdentifier = 
            [[[KGOSocialMediaController sharedController] currentFacebookUser]
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
            NSDictionary *bookmarks = 
            [FacebookModule bookmarksForMediaObjectsOfType:@"photo"];
            
            self.currentFilterBlock =
            [[
              ^(FacebookPhoto *photo) {                 
                  if ([bookmarks objectForKey:photo.identifier]) {
                      return YES;
                  }
                  return NO;
              } 
              copy] autorelease];
            
            [self refreshPhotos];            
            break;
        }
        default:
            break;
    } 
}

@end
