#import <UIKit/UIKit.h>
#import "FacebookMediaViewController.h"
#import "IconGrid.h"
#import "KGOSocialMediaController+FacebookAPI.h"

@class FacebookPhoto;

@interface FacebookPhotosViewController : FacebookMediaViewController <IconGridDelegate,
UINavigationControllerDelegate, UIImagePickerControllerDelegate, FacebookUploadDelegate> {
    
    IconGrid *_iconGrid;
    NSMutableArray *_icons;
    NSMutableSet *_displayedPhotos;
    NSMutableDictionary *_photosByID;
    CGFloat resizeFactor;
    
    UIViewController *_detailViewController;
}

- (void)didReceivePhoto:(id)result;
- (void)didReceivePhotoList:(id)result;
- (void)displayPhoto:(FacebookPhoto *)photo;
- (void)loadThumbnailsFromCache;

@end
