#import "FacebookVideosViewController.h"
#import "IconGrid.h"
#import "Foundation+KGOAdditions.h"
#import "UIKit+KGOAdditions.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "FacebookVideo.h"
#import "FacebookUser.h"
#import "FacebookModule.h"
#import "CoreDataManager.h"


static const NSInteger kTransitionImageViewTag = 0x701;

#pragma mark Private methods

@interface FacebookVideosViewController (Private)

- (void)addVideoThumbnailsToGrid;
- (CGRect)thumbnailFrame;
+ (CGRect)frameForImageInImageView:(UIImageView *)imageView;

@end

@implementation FacebookVideosViewController

@synthesize iconGrid;

- (void)getGroupVideos {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FacebookGroupReceivedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FacebookFeedDidUpdateNotification object:nil];
    
    FacebookModule *fbModule = (FacebookModule *)[KGO_SHARED_APP_DELEGATE() moduleForTag:@"facebook"];
    if (fbModule.groupID) {
        if (fbModule.latestFeedPosts) {
            for (NSDictionary *aPost in fbModule.latestFeedPosts) {
                NSString *type = [aPost stringForKey:@"type" nilIfEmpty:YES];
                if ([type isEqualToString:@"video"]) {
                    NSLog(@"video data: %@", [aPost description]);
                    FacebookVideo *aVideo = [FacebookVideo videoWithDictionary:aPost];
                    if (aVideo && ![_videoIDs containsObject:aVideo.identifier]) {
                        NSLog(@"created video %@", [aVideo description]);
                        [_videos addObject:aVideo];
                        [_videoIDs addObject:aVideo.identifier];
                    }
                }
            }
            //[_tableView reloadData];
            
        } else {
            [fbModule requestStatusUpdates:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(getGroupVideos)
                                                         name:FacebookFeedDidUpdateNotification
                                                       object:nil];
        }
        
    } else {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(getGroupVideos)
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
    
    self.title = @"Videos";
    
    resizeFactor = 1.0f;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        resizeFactor = 1.9;
    }
    CGFloat spacing = 10. * resizeFactor;
    
    CGRect frame = self.scrollView.frame;
    self.iconGrid = [[[IconGrid alloc] initWithFrame:frame] autorelease];
    self.iconGrid.delegate = self;
    self.iconGrid.spacing = GridSpacingMake(spacing, spacing);
    self.iconGrid.padding = GridPaddingMake(spacing, spacing, spacing, spacing);
    self.iconGrid.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.iconGrid.backgroundColor = [UIColor clearColor];
    
    [self.scrollView addSubview:self.iconGrid];
    
    // Add the image view used to animated transitions to the detail view.
    UIImageView *transitionImageView = 
    [[UIImageView alloc] initWithFrame:[self thumbnailFrame]];
    transitionImageView.tag = kTransitionImageViewTag;
    transitionImageView.alpha = 0.0f;
    [self.view addSubview:transitionImageView];
    [transitionImageView release];
    
    _videos = [[NSMutableArray alloc] init];
    _videoIDs = [[NSMutableSet alloc] init];
    
    [self getGroupVideos];
    [self addVideoThumbnailsToGrid];
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
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
//    [_tableView release];
    [iconGrid release];
    [_videos release];
    [_videoIDs release];
    [super dealloc];
}

#pragma mark Facebook callbacks
/*
- (void)didReceiveFeed:(id)result {
    NSArray *data = [result arrayForKey:@"data"];
    for (NSDictionary *aPost in data) {
        NSString *type = [aPost stringForKey:@"type" nilIfEmpty:YES];
        if ([type isEqualToString:@"video"]) {
            NSLog(@"video data: %@", [aPost description]);
            FacebookVideo *aVideo = [FacebookVideo videoWithDictionary:aPost];
            if (aVideo && ![_videoIDs containsObject:aVideo.identifier]) {
                NSLog(@"created video %@", [aVideo description]);
                [_videos addObject:aVideo];
                [_videoIDs addObject:aVideo.identifier];
            }
        }
    }
    [_tableView reloadData];
}
*/

#pragma Icon grid delegate

- (void)iconGridFrameDidChange:(IconGrid *)anIconGrid {
    CGSize size = self.scrollView.contentSize;
    size.height = anIconGrid.frame.size.height;
    self.scrollView.contentSize = size;
}

#pragma mark Icon grid helpers
- (void)addVideoThumbnailsToGrid {
    NSAutoreleasePool *thumbnailLoadingPool = [[NSAutoreleasePool alloc] init];
    NSMutableArray *thumbnails = [NSMutableArray arrayWithCapacity:_videos.count];
    for (FacebookVideo *video in _videos) {
        FacebookThumbnail *thumbnail = 
        [[[FacebookThumbnail alloc] initWithFrame:[self thumbnailFrame]] 
         autorelease];
        thumbnail.thumbSource = video;
        [thumbnail addTarget:self action:@selector(thumbnailTapped:) 
            forControlEvents:UIControlEventTouchUpInside];
        [thumbnails addObject:thumbnail];
    }
    if (thumbnails.count > 0) {
        self.iconGrid.icons = thumbnails;
        [self.iconGrid setNeedsLayout];
    }
    [thumbnailLoadingPool release];
}

- (CGRect)thumbnailFrame {
    return CGRectMake(0, 0, 90 * resizeFactor, 90 * resizeFactor + 40);
}

// Predicts what the size of the image in the imageView will be after 
// it is scaled to fit.
+ (CGRect)frameForImageInImageView:(UIImageView *)imageView {
    UIImage *image = imageView.image;
    CGFloat heightDiff = image.size.height - imageView.frame.size.height;
    CGFloat widthDiff = image.size.width - imageView.frame.size.width;
    
    CGRect frame = CGRectZero;
    
    CGFloat imageScale = 1.0f;
    if ((imageView.frame.size.width > 0.01f) && 
        (imageView.frame.size.height > 0.01f) && 
        (imageView.image.size.width > 0.01f) && 
        (imageView.image.size.height > 0.01f)) {
        
        if (heightDiff > widthDiff) {
            imageScale = imageView.frame.size.height / image.size.height;
        }
        else {
            imageScale = imageView.frame.size.width / image.size.width;
        }
    }
    
    CGFloat width = round(image.size.width * imageScale);
    CGFloat height = round(image.size.height * imageScale);
    CGFloat x = round((imageView.frame.size.width - width) / 2);
    CGFloat y = round((imageView.frame.size.height - height) / 2);
    return CGRectMake(x, y, width, height);
}

#pragma mark MITThumbnailDelegate
- (void)thumbnail:(MITThumbnailView *)thumbnail didLoadData:(NSData *)data {
    [[CoreDataManager sharedManager] saveData];    
}

#pragma mark Icon grid-related actions
- (void)thumbnailTapped:(FacebookThumbnail *)thumbnail {
    FacebookVideo *video = (FacebookVideo *)thumbnail.thumbSource;
        
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            _videos, @"videos", video, @"video", nil];
    
    UIImageView *transitionImageView = 
    (UIImageView *)[self.view viewWithTag:kTransitionImageViewTag];
    transitionImageView.image = thumbnail.thumbnailView.imageView.image;
//    transitionImageView.backgroundColor = [UIColor greenColor];
    CGRect transitionFrame = CGRectZero;
    CGRect frameForImage = 
    [[self class] frameForImageInImageView:thumbnail.thumbnailView.imageView];
    transitionFrame.size = frameForImage.size;
    
    transitionFrame.origin = self.iconGrid.frame.origin;
    
    transitionFrame.origin.x += thumbnail.frame.origin.x;
    transitionFrame.origin.x += thumbnail.thumbnailView.imageView.frame.origin.x;
    transitionFrame.origin.x += frameForImage.origin.x;
    
    transitionFrame.origin.y += thumbnail.frame.origin.y;
    transitionFrame.origin.y += thumbnail.thumbnailView.imageView.frame.origin.y;
    // TODO: Get rid of this fudge factor.
    transitionFrame.origin.y += (3 * frameForImage.origin.y);
    transitionImageView.frame = transitionFrame;
    transitionImageView.alpha = 1.0f;

    [UIView 
     animateWithDuration:0.2f 
     animations:
     ^{
         // Expand the transition view.
         // TODO: Proportion this size to match frameForImage.
         CGRect futureThumbnailFrame = CGRectMake(0, 60, 588, 500);
         transitionImageView.frame = futureThumbnailFrame;
         
     }
     completion:
     ^(BOOL finished) {
         // Hide the transition view.
         transitionImageView.alpha = 0.0f;
         transitionImageView.image = nil;
         
         [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameDetail 
                                forModuleTag:@"video" 
                                      params:params];         
     }];
}

@end
