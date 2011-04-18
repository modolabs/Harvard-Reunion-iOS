#import "FacebookMediaDetailViewController.h"

@class FacebookVideo;

@interface FacebookVideoDetailViewController : FacebookMediaDetailViewController 
<UIWebViewDelegate> {
    
    //MITThumbnailView *_thumbnail;
}

@property (nonatomic, retain) FacebookVideo *video;
//@property (nonatomic, retain) UIPopoverController *commentPopover;
@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) UIView *curtainView;

- (void)loadVideosFromCache;

@end
