#import "FacebookVideoDetailViewController.h"
#import "FacebookModel.h"
#import "UIKit+KGOAdditions.h"
#import "CoreDataManager.h"
#import "MediaPlayer/MediaPlayer.h"

@implementation FacebookVideoDetailViewController

@synthesize video;
@synthesize webView;

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
        
        if([self.video.src rangeOfString:@"youtube.com"].location != NSNotFound) {
            aspectRatio = CGSizeMake(10, 10);
            urlString =  [NSString stringWithFormat:@"http://www.youtube.com/embed/%@", [self youtubeId:src]];
        } else if([src rangeOfString:@"vimeo.com"].location != NSNotFound) {
            urlString = [NSString stringWithFormat:@"http://player.vimeo.com/video/%@", [self vimeoId:src]];
        } else {
            urlString = src;
        }
                
        self.webView = [[[UIWebView alloc] init] autorelease];
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
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (NSString *)postTitle {
    return self.video.name;
}

#pragma mark FacebookMediaDetailViewController
- (IBAction)commentButtonPressed:(UIBarButtonItem *)sender {
    if (UIUserInterfaceIdiomPad == UI_USER_INTERFACE_IDIOM()) {
        // Present comment view in a non-fullscreen dialog.
        FacebookCommentViewController *vc = 
        [[FacebookCommentViewController alloc] initWithNibName:
          @"FacebookCommentViewController" bundle:nil];
        vc.delegate = self;
        vc.post = self.post;
        vc.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentModalViewController:vc animated:YES];
        [vc release];
    }
    else {
        [super commentButtonPressed:sender];
    }        
}

#pragma mark UIPopoverControllerDelegate
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    // Make any post-comment changes to buttons here if necessary.
}

@end
