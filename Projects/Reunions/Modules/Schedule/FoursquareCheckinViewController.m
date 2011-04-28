#import "FoursquareCheckinViewController.h"
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
    
    self.view.backgroundColor = [[KGOTheme sharedTheme] backgroundColorForApplication];
    
    UIView *view = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 60)] autorelease];
    UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(10, 10, self.tableView.frame.size.width - 40, 24)] autorelease];
    label.text = self.eventTitle;
    label.font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyContentTitle];
    label.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyContentTitle];
    label.backgroundColor = [UIColor clearColor];
    [view addSubview:label];
    self.tableView.tableHeaderView = view;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
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
    [[[KGOSocialMediaController foursquareService] foursquareEngine] checkUserStatusForVenue:self.venue
                                                                                    delegate:self];
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = _filteredCheckinData.count;
    if (!self.isCheckedIn) {
        count++;
    }
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!self.isCheckedIn) {
        if (section == 0) {
            return 1;
        }
        section--;
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
    NSInteger section = indexPath.section;
    
    if (!self.isCheckedIn) {
        if (section == 0) {
            return [[^(UITableViewCell *cell) {
                cell.selectionStyle = UITableViewCellEditingStyleNone;
            } copy] autorelease];
        }
        section--;
    }
    
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
    if (!self.isCheckedIn) {
        if (section == 0) {
            CGFloat hPadding = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 80 : 40;
            if (!_textField) {
                _textField = [[UITextField alloc] initWithFrame:CGRectMake(10, 10, tableView.frame.size.width - hPadding, 22)];
                _textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
                _textField.borderStyle = UITextBorderStyleLine;
                _textField.placeholder = @"Add a shout with this checkin";
            } else {
                _textField.frame = CGRectMake(10, 10, tableView.frame.size.width - hPadding, 22);
            }
            
            if (!_button) {
                _button = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
                [_button setTitle:@"Check in" forState:UIControlStateNormal];
                [_button addTarget:self action:@selector(checkinButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                _button.frame = CGRectMake(tableView.frame.size.width - hPadding - 75, _textField.frame.size.height + 15, 75, 30);
                _button.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
            } else {
                _button.frame = CGRectMake(tableView.frame.size.width - hPadding - 75, _textField.frame.size.height + 15, 75, 30);
            }

            return [NSArray arrayWithObjects:_textField, _button, nil];
        }
        section--;
    }
    
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
    if (!self.isCheckedIn) {
        if (section == 0) {
            return nil;
        }
        section--;
    }
    
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
