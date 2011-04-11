#import "FacebookVideoDetailViewController.h"
#import "FacebookModel.h"
#import "UIKit+KGOAdditions.h"
#import "CoreDataManager.h"

@implementation FacebookVideoDetailViewController

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
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)displayPost {
    UIImage *image = [UIImage imageWithData:self.video.thumbData];
    [self setMediaImage:image];
    
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

- (void)setVideo:(FacebookVideo *)video {
    self.post = video;
}

- (FacebookVideo *)video {
    return (FacebookVideo *)self.post;
}

- (void)playVideo:(id)sender {
    NSString *urlString = nil;
    if ([self.video.src rangeOfString:@"fbcdn.net"].location != NSNotFound) {
        urlString = self.video.src;
    } else {
        urlString = self.video.link;
    }
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self loadVideosFromCache];
    
    self.title = @"Video";
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageWithPathName:@"common/arrow-white-right"] forState:UIControlStateNormal];
    button.frame = CGRectMake(120, 80, 80, 60);
    [button addTarget:self action:@selector(playVideo:) forControlEvents:UIControlEventTouchUpInside];
    [_mediaImageView addSubview:button];    
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

@end
