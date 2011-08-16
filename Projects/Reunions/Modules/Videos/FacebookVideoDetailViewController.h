
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import "FacebookMediaDetailViewController.h"
#import "MediaPlayer/MediaPlayer.h"

@class FacebookVideo;

@interface FacebookVideoDetailViewController : FacebookMediaDetailViewController 
<UIWebViewDelegate> {
    
    //MITThumbnailView *_thumbnail;
    MPMoviePlayerController  *_player;
}

@property (nonatomic, retain) FacebookVideo *video;
@property (nonatomic, retain) UIWebView *webView;
// If this property is set by the time the view loads, it will show the image 
// on top of the web view, then hide it when the web view finishes loading.
@property (nonatomic, retain) UIImage *loadingCurtainImage;
@property (nonatomic, retain) MPMoviePlayerController *player;

@end
