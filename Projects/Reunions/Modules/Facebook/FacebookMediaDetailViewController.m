#import "FacebookMediaDetailViewController.h"
#import "UIKit+KGOAdditions.h"
#import "Foundation+KGOAdditions.h"
#import "KGOSocialMediaController+FacebookAPI.h"
#import "KGOAppDelegate.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "FacebookModel.h"
#import <QuartzCore/QuartzCore.h>

#define LIKE_TAG 1
#define UNLIKE_TAG 2

@implementation FacebookMediaDetailViewController

@synthesize post, posts, tableView = _tableView;
@synthesize mediaView = _mediaView;
@synthesize moduleTag;
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
    [_comments release];
    self.moduleTag = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark -

- (IBAction)commentButtonPressed:(UIBarButtonItem *)sender {
    FacebookCommentViewController *vc = [[[FacebookCommentViewController alloc] initWithNibName:@"FacebookCommentViewController" bundle:nil] autorelease];
    vc.delegate = self;
    vc.post = self.post;
    [self.navigationController presentModalViewController:vc animated:YES];
}

- (IBAction)likeButtonPressed:(UIBarButtonItem *)sender {
    _likeButton.enabled = NO;
    if (_likeButton.tag == LIKE_TAG) {
        [[KGOSocialMediaController sharedController] likeFacebookPost:self.post receiver:self callback:@selector(didLikePost:)];
    } else if (_likeButton.tag == UNLIKE_TAG) {
        [[KGOSocialMediaController sharedController] unlikeFacebookPost:self.post receiver:self callback:@selector(didUnlikePost:)];
    }
}

- (void)didLikePost:(id)result {
    DLog(@"%@", [result description]);
    if ([result isKindOfClass:[NSDictionary class]] && [[result stringForKey:@"result" nilIfEmpty:YES] isEqualToString:@"true"]) {
        _likeButton.enabled = YES;
        _likeButton.tag = UNLIKE_TAG;
        [_likeButton setImage:[UIImage imageWithPathName:@"modules/facebook/unlike.png"] forState:UIControlStateNormal];
    }
}

- (void)didUnlikePost:(id)result {
    NSLog(@"%@", [result description]);
    if ([result isKindOfClass:[NSDictionary class]] && [[result stringForKey:@"result" nilIfEmpty:YES] isEqualToString:@"true"]) {
        _likeButton.enabled = YES;
        _likeButton.tag = LIKE_TAG;
        [_likeButton setImage:[UIImage imageWithPathName:@"modules/facebook/like.png"] forState:UIControlStateNormal];
    }
}

- (IBAction)bookmarkButtonPressed:(UIBarButtonItem *)sender {

}

- (IBAction)closeButtonPressed:(id)sender {
    [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameHome forModuleTag:moduleTag params:nil];
}
     
- (void)getCommentsForPost {
    NSString *objectID = self.post.postIdentifier.length ? self.post.postIdentifier : self.post.identifier;
    NSString *path = [NSString stringWithFormat:@"%@/comments", objectID];
    [[KGOSocialMediaController sharedController] requestFacebookGraphPath:path
                                                                 receiver:self
                                                                 callback:@selector(didReceiveComments:)];
}

- (void)didReceiveComments:(id)result {
    NSLog(@"%@", [result description]);
    if ([result isKindOfClass:[NSDictionary class]]) {
        NSDictionary *resultDict = (NSDictionary *)result;
        NSArray *comments = [resultDict arrayForKey:@"data"];
        for (NSDictionary *commentData in comments) {
            FacebookComment *aComment = [FacebookComment commentWithDictionary:commentData];
            aComment.parent = self.post;
        }
        
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
        [_comments release];
        _comments = [[self.post.comments sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]] retain];
        
        [_tableView reloadData];
    }
}

- (void)uploadDidComplete:(FacebookPost *)result {
    FacebookComment *aComment = (FacebookComment *)result;
    aComment.parent = self.post;
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
    [_comments release];
    _comments = [[self.post.comments sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]] retain];
    
    [self dismissModalViewControllerAnimated:YES];
    [_tableView reloadData];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _tableView.rowHeight = 100;
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
    [_comments release];
    _comments = [[self.post.comments sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]] retain];
    
    if (self.post) {
        KGODetailPager *pager = [[[KGODetailPager alloc] initWithPagerController:self delegate:self] autorelease];
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:pager] autorelease];
    }
    
    _likeButton.tag = LIKE_TAG;
    [_likeButton setImage:[UIImage imageWithPathName:@"modules/facebook/like.png"] forState:UIControlStateNormal];
    
    if (!_mediaView) {
        CGRect frame = self.view.bounds;
        frame.size.height = floor(frame.size.width * 9 / 16); // need to tweak this aspect ratio
        _mediaView = [[[UIView alloc] initWithFrame:frame] autorelease];
    } 
     
    [_mediaView initPreviewView:_mediaPreviewView];
 
    // add drop show to image background
    if (_mediaImageBackgroundView) {
        _mediaImageBackgroundView.layer.shadowOffset = CGSizeMake(0, 1);
        _mediaImageBackgroundView.layer.shadowColor = [[UIColor blackColor] CGColor];
        _mediaImageBackgroundView.layer.shadowRadius = 3.0;
        _mediaImageBackgroundView.layer.shadowOpacity = 0.8;
    }
    
    [self displayPost];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    CGFloat height;
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        CGRect frame = self.view.frame;
        height = frame.size.width * self.view.transform.c + frame.size.height * self.view.transform.d;
        height -= _buttonsBar.frame.size.height;
    } else {
        height = floor(_tableView.frame.size.width * 9 / 16);
    }
    
    _tableView.tableHeaderView.frame = CGRectMake(0, 0, _tableView.frame.size.width, height);
    _tableView.tableHeaderView = _tableView.tableHeaderView;
    [_tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    
    _tableView.scrollEnabled = UIInterfaceOrientationIsPortrait(self.interfaceOrientation);
}
    
- (void)displayPost {
    // subclasses should override this
}

- (NSString *)postTitle {
    // subclasses hsould override this
    return nil;
}

#pragma mark - KGODetailPager

- (void)pager:(KGODetailPager *)pager showContentForPage:(id<KGOSearchResult>)content {
    [[KGOSocialMediaController sharedController] disconnectFacebookRequests:self]; // stop getting data for previous post
    
    self.post = (FacebookParentPost *)content;
    [self displayPost];
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
    [_comments release];
    _comments = [[self.post.comments sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]] retain];
    
    [_tableView reloadData];
}

- (NSInteger)numberOfSections:(KGODetailPager *)pager {
    return 1;
}

- (NSInteger)pager:(KGODetailPager *)pager numberOfPagesInSection:(NSInteger)section {
    return self.posts.count;
}

- (id<KGOSearchResult>)pager:(KGODetailPager *)pager contentForPageAtIndexPath:(NSIndexPath *)indexPath {
    return [self.posts objectAtIndex:indexPath.row];
}

#pragma mark - Table view methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _comments.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *text;
    NSDate *date;
    NSString *ownerName;
    if (indexPath.row == 0) {
        text = [self postTitle];
        date = self.post.date;
        ownerName = self.post.owner.name;
    } else {
        FacebookComment *aComment = [_comments objectAtIndex:indexPath.row-1];
        NSLog(@"%@", [aComment description]);
        
        text = aComment.text;
        ownerName = aComment.owner.name;
        date = aComment.date;
    }
    

    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSInteger commentTag = 80;
    NSInteger authorTag = 81;
    NSInteger dateTag = 82;
    
    UILabel *commentLabel = (UILabel *)[cell.contentView viewWithTag:commentTag];
    if (!commentLabel) {
        UIFont *commentFont = [UIFont systemFontOfSize:15];
        commentLabel = [UILabel multilineLabelWithText:text font:commentFont width:tableView.frame.size.width - 20];
        commentLabel.tag = commentTag;
        CGRect frame = commentLabel.frame;
        frame.origin.x = 10;
        frame.origin.y = 5;
        commentLabel.frame = frame;
    } else {
        commentLabel.text = text;
    }
    [cell.contentView addSubview:commentLabel];
    
    UILabel *authorLabel = (UILabel *)[cell.contentView viewWithTag:authorTag];
    if (!authorLabel) {
        UIFont *authorFont = [UIFont systemFontOfSize:13];
        authorLabel = [UILabel multilineLabelWithText:ownerName font:authorFont width:tableView.frame.size.width - 20];
        authorLabel.tag = authorTag;
        CGRect frame = authorLabel.frame;
        frame.origin.x = 10;
        frame.origin.y = 80;
        authorLabel.frame = frame;
    } else {
        authorLabel.text = ownerName;
    }
    [cell.contentView addSubview:authorLabel];
    
    UILabel *dateLabel = (UILabel *)[cell.contentView viewWithTag:dateTag];
    NSString *dateString = [date agoString];
    if (!dateLabel) {
        UIFont *dateFont = [UIFont systemFontOfSize:13];
        dateLabel = [UILabel multilineLabelWithText:dateString font:dateFont width:tableView.frame.size.width - 20];
        dateLabel.tag = dateTag;
        CGRect frame = dateLabel.frame;
        frame.origin.x = 160;
        frame.origin.y = 80;
        dateLabel.frame = frame;
    } else {
        dateLabel.text = dateString;
    }
    [cell.contentView addSubview:dateLabel];
    
    return cell;
}

@end
