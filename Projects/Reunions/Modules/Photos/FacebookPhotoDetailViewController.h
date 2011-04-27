#import "FacebookMediaDetailViewController.h"

@class FacebookPhoto;

@interface FacebookPhotoDetailViewController : FacebookMediaDetailViewController <ConnectionWrapperDelegate> {
    
    //MITThumbnailView *_thumbnail;
}

@property (nonatomic, retain) FacebookPhoto *photo;
@property (nonatomic, retain) ConnectionWrapper *connection;
@property (nonatomic, retain) NSURL *currentURL;
@property (nonatomic, retain) UITapGestureRecognizer *tapHandler;

@end