#import "FacebookVideoDetailViewController.h"
#import "FacebookModel.h"
#import "UIKit+KGOAdditions.h"
#import "CoreDataManager.h"
#import "MediaPlayer/MediaPlayer.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "FacebookModule.h"

static const NSInteger kLoadingCurtainViewTag = 0x937;

#pragma mark Private methods

@interface FacebookVideoDetailViewController (Private)

- (void)fadeOutLoadingCurtainView;

@end

@implementation FacebookVideoDetailViewController (Private)

- (void)fadeOutLoadingCurtainView {
    UIView *loadingCurtainView = [self.webView viewWithTag:kLoadingCurtainViewTag];
    if (loadingCurtainView) {
        [UIView 
         animateWithDuration:0.4f 
         delay:0.1f
         options:UIViewAnimationOptionTransitionNone
         animations:
         ^{
             loadingCurtainView.alpha = 0.0f;
         }
         completion:nil];
    }    
}

@end


@implementation FacebookVideoDetailViewController

@synthesize video;
@synthesize webView;
//@synthesize curtainView;
@synthesize loadingCurtainImage;

/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/

- (void)dealloc {
    self.webView.delegate = nil;
    [loadingCurtainImage release];
    [webView release];
    [video release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (NSString *)youtubeId:(NSString *)source {
    // sample URL
    // http://www.youtube.com/v/d9av8-lhJS8&fs=1?autoplay
    NSArray *parts = [self.video.src componentsSeparatedByString:@"/"]; 
    NSArray *components = [[parts lastObject] componentsSeparatedByString:@"&"];
    return [components objectAtIndex:0];
}

- (NSString *)vimeoId:(NSString *)source {
    // sample URL
    // http://vimeo.com/moogaloop.swf?clip_id=8327538&autoplay=1
    NSArray *parts1 = [self.video.src componentsSeparatedByString:@"="]; 
    NSArray *parts2 = [[parts1 objectAtIndex:1] componentsSeparatedByString:@"&"];
    return  [parts2 objectAtIndex:0];
}

- (void)displayPost {
    NSString *src = self.video.src;
    if ([src rangeOfString:@"fbcdn.net"].location != NSNotFound) {
        NSURL *url = [NSURL URLWithString:src];
        MPMoviePlayerController *player = 
        [[[MPMoviePlayerController alloc] initWithContentURL:url] autorelease];
        player.shouldAutoplay = NO;
        [self.mediaView setPreviewView:player.view];
        [self.mediaView setPreviewSize:CGSizeMake(10, 10)];
    } else {
        CGSize aspectRatio = CGSizeMake(16, 9); // default aspect ratio 
        NSString *urlString;
        
        NSString *videoSourceName = [self.video videoSourceName];
        if ([videoSourceName isEqualToString:@"YouTube"]) {
            aspectRatio = CGSizeMake(10, 10);
            urlString =  [NSString stringWithFormat:@"http://www.youtube.com/embed/%@", [self youtubeId:src]];
        } else if ([videoSourceName isEqualToString:@"Vimeo"]) {
            urlString = [NSString stringWithFormat:@"http://player.vimeo.com/video/%@", [self vimeoId:src]];
        } else {
            urlString = src;
        }
                
        self.webView = [[[UIWebView alloc] init] autorelease];
        self.webView.delegate = self;
        [self.mediaView setPreviewView:self.webView];
        [self.mediaView setPreviewSize:aspectRatio];
        NSURL *url = [NSURL URLWithString:urlString];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [self.webView loadRequest:request];
    }
    
    if (!self.video.comments.count) {
        [self getCommentsForPost];
    }
}

- (void)loadVideosFromCache {
    // TODO: sort by date or whatever
    NSArray *videos = [[CoreDataManager sharedManager] objectsForEntity:FacebookVideoEntityName matchingPredicate:nil];
    for (FacebookVideo *aVideo in videos) {
        //[_photosByID setObject:aPhoto forKey:aPhoto.identifier];
        NSLog(@"found cached video %@", aVideo.identifier);
        //[self displayPhoto:aPhoto];
    }
    
    self.posts = videos;
    //[[CoreDataManager sharedManager] deleteObjects:photos];
}

- (void)setVideo:(FacebookVideo *)aVideo {
    self.post = aVideo;
}

- (FacebookVideo *)video {
    return (FacebookVideo *)self.post;
}

/*
- (void)playVideo:(id)sender {
    NSURL *url = [NSURL URLWithString:self.video.link];
    
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
}
*/
 
#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self loadVideosFromCache];
    
    self.title = @"Video";
    
    // this code overlays a play button on the video
    // for now we will try to use the built in play buttons
    // but we may need this code in the future
    /*
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageWithPathName:@"common/arrow-white-right"] forState:UIControlStateNormal];
    button.frame = CGRectMake(120, 80, 80, 60);
    [button addTarget:self action:@selector(playVideo:) forControlEvents:UIControlEventTouchUpInside];
    [self.mediaView addSubview:button];    
    */     
    
    // Show curtain image in view over the web view until the web view finishes 
    // loading.
    if (self.loadingCurtainImage) {
        CGRect loadingCurtainFrame = self.webView.frame;
        loadingCurtainFrame.origin = CGPointZero;
        UIImageView *loadingCurtainView = 
        [[UIImageView alloc] initWithFrame:loadingCurtainFrame];
        loadingCurtainView.image = self.loadingCurtainImage;
        loadingCurtainView.tag = kLoadingCurtainViewTag;
        loadingCurtainView.backgroundColor = [UIColor blackColor];
        loadingCurtainView.autoresizingMask = 
        [self.mediaView previewView].autoresizingMask;
        [self.webView addSubview:loadingCurtainView];
        [loadingCurtainView release];
    }
}

- (void)viewDidUnload
{
    self.loadingCurtainImage = nil;
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (NSString *)postTitle {
    return self.video.name;
}

#pragma mark FacebookMediaDetailViewController

- (IBAction)closeButtonPressed:(id)sender {    
    [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameHome 
                           forModuleTag:VideoModuleTag params:nil];    
}

#pragma mark FacebookMediaDetailViewController
- (NSString *)identifierForBookmark {
    return self.video.identifier;
}

- (NSString *)mediaTypeForBookmark {
    return @"video";
}

- (BOOL)hideToolbarsInLandscape {
    return NO;
}

#pragma mark UIWebViewDelegate
- (void)webViewDidFinishLoad:(UIWebView *)theWebView {
    [self fadeOutLoadingCurtainView];
}

- (void)webView:(UIWebView *)theWebView didFailLoadWithError:(NSError *)error {
    [self fadeOutLoadingCurtainView];    
}

@end
