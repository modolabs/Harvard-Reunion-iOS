#import "FoursquareCheckinViewController.h"
#import "FoursquareAddCheckinViewController.h"
#import "Foundation+KGOAdditions.h"
#import "MITThumbnailView.h"
#import "KGOTheme.h"
#import "UIKit+KGOAdditions.h"
#import "ScheduleDetailTableView.h"
#import "KGOSocialMediaController.h"

@implementation FoursquareCheckinViewController

@synthesize checkinMessage, isCheckedIn, venue, checkedInUserCount, eventTitle, parentTableView;

- (void)dealloc
{
    [[[KGOSocialMediaController foursquareService] foursquareEngine] disconnectRequestsForDelegate:self];
    self.checkinMessage = nil;
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
    
    UIView *view = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, label.frame.size.height + 20)] autorelease];
    [view addSubview:label];

    self.tableView.autoresizesSubviews = YES;
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

- (void)venueCheckinStatusFailed:(NSString *)venue withMessage:(NSString *)message
{
    // Not sure what to do here if no message
    if (message) {
        self.checkinMessage = [NSString stringWithFormat:@"Foursquare returned an error!\n%@", message, nil];
    } else {
        self.checkinMessage = @"Foursquare isn't working right now. Please try again later.";
    }
    [self.tableView reloadData];
}

- (void)venueCheckinDidSucceed:(NSString *)venue withResponse:(NSDictionary *)response
{
    [self dismissModalViewControllerAnimated:YES];
    
    NSString *message = [response objectForKey:@"message"];
    NSInteger points = [response integerForKey:@"points"];
    
    if (message) {
        NSString *pointsString = @"";
        if (points) {
            pointsString = [NSString stringWithFormat:@" You earned %d %@", points, points > 1 ? @"points" : @"point", nil];
        }
        
        self.checkinMessage = [NSString stringWithFormat:@"%@%@", message, pointsString];
    }
    
    [[[KGOSocialMediaController foursquareService] foursquareEngine] checkUserStatusForVenue:self.venue
                                                                                    delegate:self];
}
- (void)venueCheckinDidFail:(NSString *)venue withMessage:(NSString *)message
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
    if (self.checkinMessage) {
        count++;
    }
    if (count == 0) {
        count++;
    }
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.checkinMessage) {
        if (section == 0) {
            return 1;
        }
        section--;
    }
    
    if (_filteredCheckinData.count == 0) {
        return 0;
    }

    NSDictionary *groupInfo = [_filteredCheckinData objectAtIndex:section];    
    return [groupInfo integerForKey:@"count"];
}

- (KGOTableCellStyle)tableView:(UITableView *)tableView styleForCellAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellStyleSubtitle;
}

- (CellManipulator)tableView:(UITableView *)tableView manipulatorForCellAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.checkinMessage && indexPath.section == 0) {
        return [[^(UITableViewCell *cell) {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        } copy] autorelease];
    }
    
    return [[^(UITableViewCell *cell) {
        cell.accessoryView = [[KGOTheme sharedTheme] accessoryViewForType:KGOAccessoryTypeExternal];
        cell.imageView.image = [UIImage imageWithPathName:@"common/action-blank"];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
    } copy] autorelease];
}

- (NSArray *)tableView:(UITableView *)tableView viewsForCellAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    
    if (self.checkinMessage) {
        if (section == 0) {
            CGFloat width = tableView.frame.size.width - 40;
            UIFont *font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListTitle];
            UILabel *label = [UILabel multilineLabelWithText:self.checkinMessage
                                                        font:font
                                                       width:width];
            CGRect frame = label.frame;
            frame.origin.x = 10;
            frame.origin.y = 10;
            label.frame = frame;

            return [NSArray arrayWithObject:label];
        }
        section--;
    }
    
    NSDictionary *groupInfo = [_filteredCheckinData objectAtIndex:section];
    NSDictionary *itemInfo = [[groupInfo arrayForKey:@"items"] dictionaryAtIndex:indexPath.row];
    NSDictionary *userInfo = [itemInfo dictionaryForKey:@"user"];
    
    // thumbnail
    NSString *photoURL = [userInfo stringForKey:@"photo" nilIfEmpty:YES];
    MITThumbnailView *thumb = [[[MITThumbnailView alloc] initWithFrame:CGRectMake(10, 10, 24, 24)] autorelease];
    thumb.imageURL = photoURL;
    [thumb loadImage];

    NSMutableArray *nameParts = [NSMutableArray array];
    NSString *firstName = [userInfo stringForKey:@"firstName" nilIfEmpty:YES];
    if (firstName) {
        [nameParts addObject:firstName];
    }
    NSString *lastName = [userInfo stringForKey:@"lastName" nilIfEmpty:YES];
    if (lastName) {
        [nameParts addObject:lastName];
    }
    NSString *shout = [itemInfo stringForKey:@"shout" nilIfEmpty:YES];
    if (shout) {
        [nameParts addObject:[NSString stringWithFormat:@"\"%@\"", shout, nil]];
    }
    NSString *title = [nameParts componentsJoinedByString:@" "];
    
    double creationTime = (double)[itemInfo integerForKey:@"createdAt"];
    NSDate *creationDate = [NSDate dateWithTimeIntervalSince1970:creationTime];
    NSString *dateString = [creationDate agoString];

    
    CGFloat width = tableView.frame.size.width - 20 - thumb.frame.size.width;
    UIFont *titleFont = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListTitle];
    UILabel *titleLabel = [UILabel multilineLabelWithText:title
                                                     font:titleFont
                                                    width:width];
    CGRect frame = titleLabel.frame;
    frame.origin.x = thumb.frame.size.width + 20;
    frame.origin.y = 10;
    titleLabel.frame = frame;

    UIFont *subtitleFont = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListSubtitle];
    frame.origin.y += titleLabel.frame.size.height + 2;
    frame.size.height = subtitleFont.lineHeight;
    UILabel *subtitleLabel = [[[UILabel alloc] initWithFrame:frame] autorelease];
    subtitleLabel.text = dateString;
    subtitleLabel.font = subtitleFont;
    subtitleLabel.backgroundColor = [UIColor clearColor];
    subtitleLabel.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyNavListSubtitle];
    
    return [NSArray arrayWithObjects:thumb, titleLabel, subtitleLabel, nil];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.checkinMessage) {
        if (section == 0) {
            return nil;
        }
        section--;
    }

    if (_filteredCheckinData.count == 0) {
        return @"No one has checked in yet";
    }
    
    NSDictionary *groupInfo = [_filteredCheckinData objectAtIndex:section];    
    NSString *type = [groupInfo stringForKey:@"type" nilIfEmpty:YES];
    
    if ([type isEqualToString:@"self"]) {
        return @"You are here!";
        
    } else {
        NSInteger count = [groupInfo integerForKey:@"count"];
        
        if ([type isEqualToString:@"friends"]) {
            return [NSString stringWithFormat:@"%d %@ here", count, count > 1 ? @"friends are" : @"friend is", nil];
        } else {
            return [NSString stringWithFormat:@"%d other %@ here", count, count > 1 ? @"people are" : @"person is", nil];            
        }
    }
    
    return [groupInfo stringForKey:@"name" nilIfEmpty:YES];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.checkedInUserCount) {    
        if (self.checkinMessage) {
            if (indexPath.section == 0) {
                return;
            }
            indexPath = [NSIndexPath indexPathWithIndex: indexPath.section-1];
        }

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
