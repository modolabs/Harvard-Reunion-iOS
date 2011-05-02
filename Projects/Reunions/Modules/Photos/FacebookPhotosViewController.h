#import <UIKit/UIKit.h>
#import "FacebookMediaViewController.h"
#import "IconGrid.h"
#import "KGOSocialMediaController+FacebookAPI.h"

@class FacebookPhoto;

typedef BOOL (^PhotoTest)(FacebookPhoto *photo);

@interface FacebookPhotosViewController : FacebookMediaViewController <IconGridDelegate,
UINavigationControllerDelegate, UIImagePickerControllerDelegate, FacebookUploadDelegate,
UIActionSheetDelegate, UIPopoverControllerDelegate> {
    
    IconGrid *_iconGrid;
    NSMutableArray *_icons;
    NSMutableArray *_displayedPhotos;
    // This is the unfiltered collection of photos.
    NSMutableDictionary *_photosByID; 
    CGFloat resizeFactor;
    
    UIViewController *_detailViewController;
    NSUInteger _photosRequestCount;
}

- (void)didReceivePhoto:(id)result;
- (void)didReceivePhotoList:(id)result;
- (void)displayPhoto:(FacebookPhoto *)photo;
- (void)loadThumbnailsFromCache;

@property (nonatomic, retain) UIPopoverController *photoPickerPopover;
@property (nonatomic, retain) PhotoTest currentFilterBlock;

@end
