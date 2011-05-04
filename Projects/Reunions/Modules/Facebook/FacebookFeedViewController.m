#import "FacebookFeedViewController.h"
#import "KGOSocialMediaController+FacebookAPI.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "FacebookModule.h"
#import "Foundation+KGOAdditions.h"
#import "UIKit+KGOAdditions.h"
#import "MITThumbnailView.h"
#import "FacebookModel.h"
#import "FacebookCommentViewController.h"

@implementation FacebookFeedViewController

@synthesize feedPosts;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.feedPosts = nil;
    _facebookModule = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)facebookFeedDidUpdate:(NSNotification *)aNotification
{
    NSMutableArray *statusUpdates = [NSMutableArray array];
    for (NSDictionary *aPost in _facebookModule.latestFeedPosts) {
        NSString *type = [aPost stringForKey:@"type" nilIfEmpty:YES];
        if ([type isEqualToString:@"status"]) {
            [statusUpdates addObject:aPost];
        }
    }
    self.feedPosts = statusUpdates;
    
    [self reloadDataForTableView:self.tableView];
}

- (void)postButtonPressed:(id)sender
{
    if (![[KGOSocialMediaController facebookService] isSignedIn]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(postButtonPressed:)
                                                     name:FacebookDidLoginNotification object:nil];
        [[KGOSocialMediaController facebookService] signin];
        return;
    }
    
    FacebookCommentViewController *vc = [[[FacebookCommentViewController alloc] initWithNibName:@"FacebookCommentViewController"
                                                                                         bundle:nil] autorelease];
    vc.delegate = self;
    vc.profileID = _facebookModule.groupID;
    
    UINavigationController *navC = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
    navC.navigationBar.barStyle = UIBarStyleBlack;
    navC.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [self presentModalViewController:navC animated:YES];
}

- (void)uploadDidComplete:(FacebookPost *)result
{
    [self dismissModalViewControllerAnimated:YES];
    [_facebookModule requestStatusUpdates:nil];
}

#pragma mark - View lifecycle

- (void)refreshNavBarItems
{
    NSString *title = nil;
    if ([[KGOSocialMediaController facebookService] isSignedIn]) {
        title = @"Post";
        
        if (!self.feedPosts.count) {
            [_facebookModule requestStatusUpdates:nil];
        }
        
    } else {
        title = @"Sign in";
    }
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:title
                                                                               style:UIBarButtonItemStyleDone
                                                                              target:self
                                                                              action:@selector(postButtonPressed:)] autorelease];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _facebookModule = (FacebookModule *)[KGO_SHARED_APP_DELEGATE() moduleForTag:@"facebook"];
    NSMutableArray *statusUpdates = [NSMutableArray array];
    for (NSDictionary *aPost in _facebookModule.latestFeedPosts) {
        NSString *type = [aPost stringForKey:@"type" nilIfEmpty:YES];
        if ([type isEqualToString:@"status"]) {
            [statusUpdates addObject:aPost];
        }
    }
    self.feedPosts = statusUpdates;
    
    if (![[KGOSocialMediaController facebookService] isSignedIn]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(refreshNavBarItems)
                                                     name:FacebookDidLoginNotification
                                                   object:nil];
        
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(facebookFeedDidUpdate:)
                                                 name:FacebookStatusDidUpdateNotification
                                               object:nil];
    
    [self refreshNavBarItems];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (CellManipulator)tableView:(UITableView *)tableView manipulatorForCellAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *title = nil;
    if (![[KGOSocialMediaController facebookService] isSignedIn]) {
        title = @"Sign into Facebook to post an update";
    }
    
    return [[^(UITableViewCell *cell) {
        cell.textLabel.text = title;
        cell.selectionStyle = UITableViewCellEditingStyleNone;
    } copy] autorelease];
}

- (NSArray *)tableView:(UITableView *)tableView viewsForCellAtIndexPath:(NSIndexPath *)indexPath
{
    if (![[KGOSocialMediaController facebookService] isSignedIn]) {
        return nil;
    }

    NSDictionary *aPost = [self.feedPosts objectAtIndex:indexPath.row];

    NSString *title = [aPost stringForKey:@"message" nilIfEmpty:YES];
    NSDictionary *from = [aPost dictionaryForKey:@"from"];
    FacebookUser *user = [FacebookUser userWithDictionary:from];
    NSString *username = user.name;
    
    NSDate *date = nil;
    NSString *dateString = [aPost stringForKey:@"updated_time" nilIfEmpty:YES];
    if (dateString) {
        date = [FacebookModule dateFromRFC3339DateTimeString:dateString];
    }
    
    MITThumbnailView *thumbView = [[[MITThumbnailView alloc] initWithFrame:CGRectMake(10, 10, 50, 50)] autorelease];
    if (user.identifier) {
        thumbView.imageURL = [[KGOSocialMediaController facebookService] imageURLForGraphObject:user.identifier];
        [thumbView loadImage];
    }
    
    UIFont *titleFont = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyBodyText];
    UIFont *detailFont = [UIFont systemFontOfSize:12];
    CGFloat width = tableView.frame.size.width - 20 - thumbView.frame.size.width;

    // tweet text
    UILabel *titleLabel = [UILabel multilineLabelWithText:title
                                                     font:titleFont
                                                    width:width];
    CGRect frame = titleLabel.frame;
    frame.origin.x = thumbView.frame.size.width + 20;
    frame.origin.y = 10;
    UIFont *userFont = [UIFont boldSystemFontOfSize:12];
    CGSize size = [username sizeWithFont:userFont];
    frame.size = size;

    // username
    UILabel *userLabel = [[[UILabel alloc] initWithFrame:frame] autorelease];
    userLabel.font = userFont;
    userLabel.text = username;
    frame.origin.y += userLabel.frame.size.height + 2;

    frame.size = titleLabel.frame.size;
    titleLabel.frame = frame;

    // tweet time
    frame.origin.y += titleLabel.frame.size.height + 2;
    frame.size.height = detailFont.lineHeight;

    UILabel *subtitleLabel = [[[UILabel alloc] initWithFrame:frame] autorelease];
    subtitleLabel.text = [date agoString];
    subtitleLabel.font = detailFont;
    subtitleLabel.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyNavListSubtitle];
    
    return [NSArray arrayWithObjects:thumbView, userLabel, titleLabel, subtitleLabel, nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([[KGOSocialMediaController facebookService] isSignedIn]) {
        return self.feedPosts.count;
    } else {
        return 1;
    }
}

@end
