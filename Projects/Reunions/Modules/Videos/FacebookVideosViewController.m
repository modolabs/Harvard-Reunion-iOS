#import "FacebookVideosViewController.h"
#import "IconGrid.h"
#import "Foundation+KGOAdditions.h"
#import "UIKit+KGOAdditions.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "FacebookVideo.h"
#import "FacebookUser.h"
#import "FacebookModule.h"
#import "CoreDataManager.h"

#pragma mark Private methods

@interface FacebookVideosViewController (Private)

- (void)addVideoThumbnailsToGrid;

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
        CGRect frame = 
        CGRectMake(0, 0, 90 * resizeFactor, 90 * resizeFactor + 40);
        FacebookThumbnail *thumbnail = 
        [[[FacebookThumbnail alloc] initWithFrame:frame] autorelease];
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

#pragma mark MITThumbnailDelegate
- (void)thumbnail:(MITThumbnailView *)thumbnail didLoadData:(NSData *)data {
    [[CoreDataManager sharedManager] saveData];    
}

#pragma mark Icon grid-related actions
- (void)thumbnailTapped:(FacebookThumbnail *)sender {
    FacebookVideo *video = (FacebookVideo *)sender.thumbSource;
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            _videos, @"videos", video, @"video", nil];
    [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameDetail 
                           forModuleTag:@"video" 
                                 params:params];
}

@end
