#import "FoursquareCheckinViewController.h"
#import "FoursquareAddCheckinViewController.h"
#import "Foundation+KGOAdditions.h"
#import "MITThumbnailView.h"
#import "KGOTheme.h"
#import "UIKit+KGOAdditions.h"
#import "ScheduleDetailTableView.h"
#import "KGOSocialMediaController.h"

@implementation FoursquareCheckinViewController

@synthesize isCheckedIn, venue, checkedInUserCount, eventTitle, parentTableView;

- (void)dealloc
{
    [[[KGOSocialMediaController foursquareService] foursquareEngine] disconnectRequestsForDelegate:self];
    self.checkinData = nil;
    self.eventTitle = nil;
    self.venue = nil;
    [_button release];
    [_textField release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGFloat width = self.tableView.frame.size.width - 20;
    
    UIView *view = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 60)] autorelease];
    UIFont *font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyContentTitle];
    CGSize size = [self.eventTitle sizeWithFont:font
                              constrainedToSize:CGSizeMake(width, font.lineHeight * 4)
                                  lineBreakMode:UILineBreakModeTailTruncation];
    UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(10, 10, width, size.height)] autorelease];
    label.text = self.eventTitle;
    label.font = font;
    label.numberOfLines = 4;
    label.lineBreakMode = UILineBreakModeTailTruncation;
    label.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyContentTitle];
    label.backgroundColor = [UIColor clearColor];
    [view addSubview:label];
    self.tableView.tableHeaderView = view;
    
    [[[KGOSocialMediaController foursquareService] foursquareEngine] checkUserStatusForVenue:self.venue
                                                                                    delegate:self];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
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

#pragma mark

- (void)showCheckinDialog:(id)sender
{
    FoursquareAddCheckinViewController *vc = [[[FoursquareAddCheckinViewController alloc] initWithNibName:@"FoursquareAddCheckinViewController"
                                                                                                   bundle:nil] autorelease];
    vc.parent = self;
    vc.venue = self.venue;
    
    UINavigationController *navC = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
    navC.navigationBar.barStyle = UIBarStyleBlack;
    navC.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [self presentModalViewController:navC animated:YES];
}

- (void)checkinButtonPressed:(id)sender
{
    [[[KGOSocialMediaController foursquareService] foursquareEngine] checkinVenue:self.venue
                                                                         delegate:self
                                                                          message:_textField.text];
}

// here we are relying on the fact that venueCheckinStatusReceived is called
// before didReceiveCheckins so we don't have to reload the table twice
- (void)venueCheckinStatusReceived:(BOOL)status forVenue:(NSString *)aVenue
{
    self.isCheckedIn = status;
    
    if (self.isCheckedIn) {
        self.navigationItem.rightBarButtonItem = nil;
    } else {
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Check in Here"
                                                                                   style:UIBarButtonItemStyleDone
                                                                                  target:self
                                                                                  action:@selector(showCheckinDialog:)] autorelease];
    }
    
    [self.parentTableView venueCheckinStatusReceived:status forVenue:aVenue];
}

- (void)didReceiveCheckins:(NSArray *)checkins total:(NSInteger)total forVenue:(NSString *)aVenue
{
    self.checkinData = checkins;
    self.checkedInUserCount = total;
    
    [self.parentTableView didReceiveCheckins:checkins total:total forVenue:aVenue];
    
    [self.tableView reloadData];
}

- (void)venueCheckinDidSucceed:(NSString *)venue
{
    [self dismissModalViewControllerAnimated:YES];
    [[[KGOSocialMediaController foursquareService] foursquareEngine] checkUserStatusForVenue:self.venue
                                                                                    delegate:self];
}
- (void)venueCheckinDidFail:(NSString *)venue;
{
    [self dismissModalViewControllerAnimated:YES];    
}

- (void)setCheckinData:(NSArray *)checkinData
{
    [_checkinData release];
    _checkinData = [checkinData retain];
    
    [_filteredCheckinData release];
    _filteredCheckinData = nil;
    
    if (_checkinData) {
        NSMutableArray *mutableData = [NSMutableArray array];
        for (NSDictionary *groupInfo in self.checkinData) {
            NSInteger localCount = [groupInfo integerForKey:@"count"];
            if (localCount) {
                [mutableData addObject:groupInfo];
            }
        }
        
        _filteredCheckinData = [mutableData copy];
    }
}

- (NSArray *)checkinData
{
    return _checkinData;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = _filteredCheckinData.count;
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSDictionary *groupInfo = [_filteredCheckinData objectAtIndex:section];
    return [groupInfo integerForKey:@"count"];
}

- (KGOTableCellStyle)tableView:(UITableView *)tableView styleForCellAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellStyleSubtitle;
}

- (CellManipulator)tableView:(UITableView *)tableView manipulatorForCellAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    
    NSDictionary *groupInfo = [_filteredCheckinData objectAtIndex:section];
    NSDictionary *itemInfo = [[groupInfo arrayForKey:@"items"] dictionaryAtIndex:indexPath.row];
    NSDictionary *userInfo = [itemInfo dictionaryForKey:@"user"];
    
    NSMutableArray *nameParts = [NSMutableArray array];
    NSString *firstName = [userInfo stringForKey:@"firstName" nilIfEmpty:YES];
    if (firstName) {
        [nameParts addObject:firstName];
    }
    NSString *lastName = [userInfo stringForKey:@"lastName" nilIfEmpty:YES];
    if (lastName) {
        [nameParts addObject:lastName];
    }

    double creationTime = (double)[itemInfo integerForKey:@"createdAt"];
    NSDate *creationDate = [NSDate dateWithTimeIntervalSince1970:creationTime];
    NSString *dateString = [creationDate agoString];

    return [[^(UITableViewCell *cell) {
        cell.textLabel.text = [nameParts componentsJoinedByString:@" "];
        cell.detailTextLabel.text = dateString;
        cell.accessoryView = [[KGOTheme sharedTheme] accessoryViewForType:KGOAccessoryTypeExternal];
        cell.imageView.image = [UIImage imageWithPathName:@"common/action-blank"];
    } copy] autorelease];
}

- (NSArray *)tableView:(UITableView *)tableView viewsForCellAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    
    NSDictionary *groupInfo = [_filteredCheckinData objectAtIndex:section];
    NSDictionary *itemInfo = [[groupInfo arrayForKey:@"items"] dictionaryAtIndex:indexPath.row];
    NSDictionary *userInfo = [itemInfo dictionaryForKey:@"user"];
    NSString *photoURL = [userInfo stringForKey:@"photo" nilIfEmpty:YES];
    MITThumbnailView *thumb = [[[MITThumbnailView alloc] initWithFrame:CGRectMake(10, 10, 24, 24)] autorelease];
    thumb.imageURL = photoURL;
    [thumb loadImage];
    return [NSArray arrayWithObject:thumb];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSDictionary *groupInfo = [_filteredCheckinData objectAtIndex:section];
    NSString *groupName = [groupInfo stringForKey:@"name" nilIfEmpty:YES];
    //NSInteger count = [groupInfo integerForKey:@"count"];
    
    //return [NSString stringWithFormat:@"%d %@", count, groupName];
    return groupName;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.checkedInUserCount) {    
        NSDictionary *groupInfo = [_filteredCheckinData objectAtIndex:indexPath.section];
        NSDictionary *itemInfo = [[groupInfo arrayForKey:@"items"] dictionaryAtIndex:indexPath.row];
        NSDictionary *userInfo = [itemInfo dictionaryForKey:@"user"];
        NSString *userID = [userInfo stringForKey:@"id" nilIfEmpty:YES];
        
        NSString *urlString = [NSString stringWithFormat:@"https://foursquare.com/mobile/user/%@", userID];
        NSURL *url = [NSURL URLWithString:urlString];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}

@end
