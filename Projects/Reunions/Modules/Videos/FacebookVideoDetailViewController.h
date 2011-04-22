#import "FacebookMediaDetailViewController.h"

@class FacebookVideo;

@interface FacebookVideoDetailViewController : FacebookMediaDetailViewController 
<UIWebViewDelegate> {
    
    //MITThumbnailView *_thumbnail;
}

@property (nonatomic, retain) FacebookVideo *video;
@property (nonatomic, retain) UIWebView *webView;
// If this property is set by the time the view loads, it will show the image 
// on top of the web view, then hide it when the web view finishes loading.
@property (nonatomic, retain) UIImage *loadingCurtainImage;

- (void)loadVideosFromCache;

@end
