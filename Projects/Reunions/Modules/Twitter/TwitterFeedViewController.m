#import "TwitterFeedViewController.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "TwitterModule.h"
#import "Foundation+KGOAdditions.h"
#import "UIKit+KGOAdditions.h"
#import "TwitterViewController.h"

@implementation TwitterFeedViewController

@synthesize latestTweets;

- (void)dealloc
{
    self.latestTweets = nil;
    twitterModule = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)twitterFeedDidUpdate:(NSNotification *)aNotification {
    self.latestTweets = twitterModule.latestTweets;
    [self reloadDataForTableView:self.tableView];
}

- (void)loginButtonPressed:(UIButton *)sender {

    // TODO: this isn't really what we want -- we want the
    // social media controller to handle this for us
    TwitterViewController *twitterVC = [[[TwitterViewController alloc] init] autorelease];
    [KGO_SHARED_APP_DELEGATE() presentAppModalNavigationController:twitterVC animated:YES];
}

- (void)sendButtonPressed:(UIButton *)sender {
    ;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    twitterModule = (TwitterModule *)[KGO_SHARED_APP_DELEGATE() moduleForTag:@"twitter"];
    self.latestTweets = twitterModule.latestTweets;
    
    if (!self.latestTweets) {
        [twitterModule requestStatusUpdates:nil];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(twitterFeedDidUpdate:)
                                                 name:TwitterStatusDidUpdateNotification
                                               object:nil];
    
    // TODO: don't hard code UI settings
    _loginView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 70)];
    _loginView.backgroundColor = [UIColor colorWithHexString:@"99CCFF"];
    UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(20, 20, 180, 30)] autorelease];
    label.text = NSLocalizedString(@"You are not logged in", nil);
    label.backgroundColor = [UIColor clearColor];
    UIButton *loginButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [loginButton setTitle:NSLocalizedString(@"Log in", nil) forState:UIControlStateNormal];
    [loginButton addTarget:self action:@selector(loginButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    loginButton.frame = CGRectMake(220, 20, 80, 30);
    [_loginView addSubview:label];
    [_loginView addSubview:loginButton];
    
    self.tableView.tableHeaderView = _loginView;
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


- (NSArray *)tableView:(UITableView *)tableView viewsForCellAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSDictionary *aTweet = [self.latestTweets objectAtIndex:indexPath.row];
    
    NSString *title = [aTweet stringForKey:@"text" nilIfEmpty:YES];
    NSString *user = [aTweet stringForKey:@"from_user" nilIfEmpty:YES];
    NSString *dateString = [aTweet stringForKey:@"created_at" nilIfEmpty:YES];
    NSDate *date = [[twitterModule twitterDateFormatter] dateFromString:dateString];

    UIFont *titleFont = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListTitle];
    UIFont *detailFont = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListSubtitle];
    CGFloat width = tableView.frame.size.width - 20;
    
    UILabel *titleLabel = [UILabel multilineLabelWithText:title
                                                     font:titleFont
                                                    width:width];
    CGRect frame = titleLabel.frame;
    frame.origin.x = 5;
    frame.origin.y = 5;
    titleLabel.frame = frame;

    frame.origin.y += titleLabel.frame.size.height + 10;
    frame.size.height = detailFont.lineHeight + 4;
    UILabel *subtitleLabel = [[[UILabel alloc] initWithFrame:frame] autorelease];
    subtitleLabel.text = [NSString stringWithFormat:@"%@ %@", user, [date agoString]];
    subtitleLabel.font = detailFont;
    subtitleLabel.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyNavListSubtitle];
    
    return [NSArray arrayWithObjects:titleLabel, subtitleLabel, nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.latestTweets.count;
}


@end
