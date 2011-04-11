#import <UIKit/UIKit.h>
#import "FacebookMediaViewController.h"
#import "IconGrid.h"
#import "MITThumbnailView.h"
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

@interface FacebookThumbnail : UIControl <MITThumbnailDelegate> {
    UILabel *_label;
    MITThumbnailView *_thumbnail;
    CGFloat _rotationAngle;
    FacebookPhoto *_photo;
}

@property (nonatomic) CGFloat rotationAngle;
@property (nonatomic, retain) FacebookPhoto *photo;

- (void)highlightIntoFrame:(CGRect)frame;
- (void)hide;

@end