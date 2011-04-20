#import "FacebookVideosViewController.h"
#import "IconGrid.h"
#import "Foundation+KGOAdditions.h"
#import "UIKit+KGOAdditions.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "FacebookVideo.h"
#import "FacebookUser.h"
#import "FacebookModule.h"
#import "CoreDataManager.h"
#import <QuartzCore/QuartzCore.h>

typedef enum {
    kTransitionImageViewTag = 0x701,
    kTransitionViewTag
}
VideosViewTags;

#pragma mark Private methods

@interface FacebookVideosViewController (Private)

- (void)requestVideosFromFeed;
- (void)addVideoThumbnailsToGrid;
- (CGRect)thumbnailFrame;
+ (CGRect)frameForImage:(UIImage *)image 
                inFrame:(CGRect)frame 
             withMargin:(CGFloat)margin;
- (CGRect)frameForTransitionViewInMainViewForThumbnail:(FacebookThumbnail *)thumbnail;
+ (UIImage *)screenShotOfView:(UIView *)targetView;

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
            [self addVideoThumbnailsToGrid];            
        } 
        else {
            [self requestVideosFromFeed];                     
        }        
    } 
    else {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(getGroupVideos)
                                                     name:FacebookGroupReceivedNotification
                                                   object:nil];
    }
}

- (void)requestVideosFromFeed {    
    FacebookModule *fbModule = 
    (FacebookModule *)[KGO_SHARED_APP_DELEGATE() moduleForTag:@"facebook"];
    [fbModule requestStatusUpdates:nil];
    [[NSNotificationCenter defaultCenter] 
     addObserver:self
     selector:@selector(getGroupVideos)
     name:FacebookFeedDidUpdateNotification
     object:nil];                     
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
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {    
        // Add the view used to animated transitions to the detail view.
        UIView *transitionView = [[UIView alloc] initWithFrame:CGRectZero];
        transitionView.tag = kTransitionViewTag;
        transitionView.backgroundColor = [UIColor blackColor];
        transitionView.alpha = 0.0f;
        [self.view addSubview:transitionView];
        
        UIImageView *transitionImageView = 
        [[UIImageView alloc] initWithFrame:CGRectZero];
        transitionImageView.tag = kTransitionImageViewTag;
        transitionImageView.alpha = 0.0f;
        [transitionView addSubview:transitionImageView];
        
        [transitionImageView release];
        [transitionView release];
    }
    
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

// Predicts what the size of the image will be after it is scaled to fit the 
// given frame.
+ (CGRect)frameForImage:(UIImage *)image 
                inFrame:(CGRect)frame 
             withMargin:(CGFloat)margin {
    
    CGRect innerFrame =
    CGRectMake(frame.origin.x + margin, frame.origin.y + margin, 
               frame.size.width - 2 * margin, frame.size.height - 2 * margin);        
    
    CGFloat heightDiff = image.size.height - innerFrame.size.height;
    CGFloat widthDiff = image.size.width - innerFrame.size.width;
    
    CGFloat imageScale = 1.0f;
    if ((innerFrame.size.width > 0.01f) && 
        (innerFrame.size.height > 0.01f) && 
        (innerFrame.size.width > 0.01f) && 
        (innerFrame.size.height > 0.01f)) {
        
        if (abs(heightDiff) > abs(widthDiff)) {
            imageScale = innerFrame.size.height / image.size.height;
        }
        else {
            imageScale = innerFrame.size.width / image.size.width;
        }
    }
    
    CGFloat width = round(image.size.width * imageScale);
    CGFloat height = round(image.size.height * imageScale);
    CGFloat x = round((innerFrame.size.width - width) / 2);
    CGFloat y = round((innerFrame.size.height - height) / 2);
    
    return CGRectMake(x + margin, y + margin, width, height);
}

- (CGRect)frameForTransitionViewInMainViewForThumbnail:(FacebookThumbnail *)thumbnail {
    // The thumbnail is inside of the icon grid, which is inside of the main view.
    CGRect frame = thumbnail.frame;
    frame.origin.x += self.iconGrid.frame.origin.x;
    frame.origin.y += self.iconGrid.frame.origin.y;
    return frame;
}


// http://stackoverflow.com/questions/2214957/how-do-i-take-a-screen-shot-of-a-uiview
+ (UIImage *)screenShotOfView:(UIView *)targetView {
    UIGraphicsBeginImageContext(targetView.frame.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [targetView.layer renderInContext:context];
    UIImage *screenShot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return screenShot;
}


#pragma mark MITThumbnailDelegate
- (void)thumbnail:(MITThumbnailView *)thumbnail didLoadData:(NSData *)data {
    [[CoreDataManager sharedManager] saveData];    
}

#pragma mark Icon grid-related actions
- (void)thumbnailTapped:(FacebookThumbnail *)thumbnail {
    FacebookVideo *video = (FacebookVideo *)thumbnail.thumbSource;
        
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                _videos, @"videos", video, @"video", nil];
        [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameDetail 
                               forModuleTag:@"video" 
                                     params:params]; 
    }
    else {
        // Animate the navigation transition on the iPad.
        NSString *videoSourceName = [video videoSourceName];
        
        // Set up transition animation views.   
        UIView *transitionView = [self.view viewWithTag:kTransitionViewTag];
        transitionView.frame = 
        [self frameForTransitionViewInMainViewForThumbnail:thumbnail];
        
        UIImageView *transitionImageView = 
        (UIImageView *)[transitionView viewWithTag:kTransitionImageViewTag];
        transitionImageView.image = thumbnail.thumbnailView.imageView.image;
        
        // Set up inner image view frame.
        CGRect frameForImage = 
        [[self class] frameForImage:thumbnail.thumbnailView.imageView.image
                            inFrame:thumbnail.thumbnailView.imageView.frame
                         withMargin:0];
        // Move it over a bit so that it doesn't look like it's jutting out 
        // of the parent frame when it starts animating.
        frameForImage.origin.x += 20; 
        transitionImageView.frame = frameForImage;
        
        // Calculate the frames for these views, post-animation.
        CGRect predictedDetailViewWebFrame = CGRectMake(5, 60, 598, 500);
        CGFloat predictedImageMargin = 0.0f;
        if ([videoSourceName isEqualToString:@"YouTube"]) {
            predictedImageMargin = 44.0f;
        }
        CGRect predictedImageInFutureWebViewFrame = 
        [[self class] frameForImage:thumbnail.thumbnailView.imageView.image
                            inFrame:predictedDetailViewWebFrame
                         withMargin:predictedImageMargin];
        
        if ([videoSourceName isEqualToString:@"YouTube"]) {
            // YouTube videos are just a little lower and shorter than 
            // the thumbnail would seem to predict.
            predictedImageInFutureWebViewFrame.origin.y += 10.0f;
            predictedImageInFutureWebViewFrame.size.height -= 30.0f;
        }
        else if ([videoSourceName isEqualToString:@"Vimeo"]) {
            // Vimeo videos end up taller than the thumbnail, in a proportional 
            // sense.
            predictedImageInFutureWebViewFrame.origin.y -= 25.0f;
            predictedImageInFutureWebViewFrame.size.height += 50.0f;
        }
            
        transitionView.alpha = 1.0f;             
        
        [UIView 
         animateWithDuration:0.75f
         animations:
         ^{         
             transitionView.frame = predictedDetailViewWebFrame;
             
             [UIView 
              animateWithDuration:0.5f
              delay:0.25f
              options:UIViewAnimationOptionTransitionNone
              animations:
              ^{                  
                  transitionImageView.alpha = 1.0f;
                  transitionImageView.frame = 
                  predictedImageInFutureWebViewFrame;
              }
              completion:nil];
         }
         completion:
         ^(BOOL finished) {
             // This is the image the detail will display over the web view 
             // while it is loading.
             UIImage *curtainImage = 
             [[self class] screenShotOfView:transitionView];
             
             // Hide the transition view.
             transitionView.alpha = 0.0f;
             transitionImageView.alpha = 0.0f;             
             transitionImageView.image = nil;
             
             NSDictionary *params = 
             [NSDictionary dictionaryWithObjectsAndKeys:
              _videos, @"videos", video, @"video", 
              curtainImage, @"loadingCurtainImage", nil];
             
             [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameDetail 
                                    forModuleTag:@"video" 
                                          params:params];         
         }];
    }
}

#pragma mark FacebookMediaViewController
- (void)facebookDidLogin:(NSNotification *)aNotification
{
    [super facebookDidLogin:aNotification];
    [self requestVideosFromFeed];
}

@end
