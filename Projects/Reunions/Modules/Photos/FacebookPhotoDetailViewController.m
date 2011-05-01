#import "FacebookPhotoDetailViewController.h"
#import "UIKit+KGOAdditions.h"
#import "Foundation+KGOAdditions.h"
#import "KGOSocialMediaController+FacebookAPI.h"
#import "KGOAppDelegate.h"
#import "CoreDataManager.h"
#import "FacebookModel.h"
#import "FacebookModule.h"

@interface FacebookPhotoDetailViewController (Private)

- (void)requestImage:(FacebookPhoto *)photo;
- (void)handlePreviewTap:(UIRotationGestureRecognizer *)gestureRecognizer;
- (void)fadeControlsAppropriately;
- (void)fadeInControls;
- (void)fadeOutControls;

@end

@implementation FacebookPhotoDetailViewController

@synthesize connection;
@synthesize currentURL;

/*
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
 {
 self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
 if (self) {
 // Custom initialization
 }
 return self;
 }
 */
- (void)dealloc
{
    [currentURL release];
    [connection release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark -

- (void)displayPost {
    NSLog(@"%@", self.photo);
    
    UIImage *image = nil;
    if (self.photo.data) {
        image = [UIImage imageWithData:self.photo.data];
    } else if(self.photo.thumbData) {
        image = [UIImage imageWithData:self.photo.thumbData];
        [self requestImage:self.photo];
    }
    
    UIImageView *imageView = [[[UIImageView alloc] initWithImage:image] autorelease];
    [self.mediaView setPreviewView:imageView];
    [self.mediaView setPreviewSize:image.size];
    
    if (!self.photo.comments.count) {
        [self getCommentsForPost];
    }
}

- (void)setPhoto:(FacebookPhoto *)photo {
    self.post = photo;
}

- (FacebookPhoto *)photo {
    return (FacebookPhoto *)self.post;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Photo";
}

- (void)viewDidUnload
{
    self.photo = nil;
    self.currentURL = nil;
    self.connection.delegate = nil;
    self.connection = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

#pragma mark - Table view methods

- (NSString *)postTitle {
    return  self.photo.title;
}

- (void)requestImage:(FacebookPhoto *)photo {
    
    if ([self.connection isConnected]) {
        [self.connection cancel];
    }
    
    if (!self.connection) {
        self.connection = [[[ConnectionWrapper alloc] initWithDelegate:self] autorelease];
    }
    self.currentURL = [NSURL URLWithString:photo.src];
    if ([self.connection requestDataFromURL:self.currentURL allowCachedResponse:YES]) {    
        [KGO_SHARED_APP_DELEGATE() showNetworkActivityIndicator];
    }
}

// ConnectionWrapper delegate
- (void)connection:(ConnectionWrapper *)wrapper handleData:(NSData *)data {
    // TODO: If memory usage becomes a concern, convert images to PNG using UIImagePNGRepresentation(). PNGs use considerably less RAM.
    if (connection.theURL == self.currentURL) {
        UIImage *image = [UIImage imageWithData:data];
        if(image) {
            self.photo.data = data;
            [[CoreDataManager sharedManager] saveData];
            UIImageView *imageView = (UIImageView *)self.mediaView.previewView;
            imageView.image = [UIImage imageWithData:data];
        }
    }
    
    self.connection = nil;
    [KGO_SHARED_APP_DELEGATE() hideNetworkActivityIndicator];
}

- (void)connection:(ConnectionWrapper *)wrapper handleConnectionFailureWithError:(NSError *)error {
    self.connection = nil;
    [KGO_SHARED_APP_DELEGATE() hideNetworkActivityIndicator];
}

#pragma mark FacebookMediaDetailViewController
- (NSString *)identifierForBookmark {
    return self.photo.identifier;
}

- (NSString *)mediaTypeForBookmark {
    return @"photo";
}

- (NSString *)mediaTypeHumanReadableName{
    return @"photo";
}

- (BOOL)hideToolbarsInLandscape {
    return YES;
}
@end
