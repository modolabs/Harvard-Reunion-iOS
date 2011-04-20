#import "ScheduleDetailTableView.h"
#import "KGOSocialMediaController+Foursquare.h"
#import "KGOFoursquareEngine.h"
#import "UIKit+KGOAdditions.h"
#import "ScheduleEventWrapper.h"
#import "Foundation+KGOAdditions.h"
#import "ReunionDetailPageHeaderView.h"
#import "CalendarDataManager.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "FoursquareCheckinViewController.h"

#define CHECKIN_STATUS_CHECKED_IN 438
#define CHECKIN_STATUS_NOT_CHECKED_IN 41
#define CHECKIN_STATUS_UNKNOWN 768


@implementation ScheduleDetailTableView

@synthesize mapView;

- (void)foursquareButtonPressed:(id)sender
{
    FoursquareCheckinViewController *checkinVC = [[[FoursquareCheckinViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
    UINavigationController *navC = [[[UINavigationController alloc] initWithRootViewController:checkinVC] autorelease];
    UIBarButtonItem *item = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                           target:self.viewController
                                                                           action:@selector(dismissModalViewControllerAnimated:)] autorelease];
    checkinVC.navigationItem.rightBarButtonItem = item;
    checkinVC.checkinData = _checkedInUsers;
    checkinVC.checkedInUserCount = _checkedInUserCount;
    checkinVC.venue = _foursquareVenue;
    checkinVC.eventTitle = self.event.title;
    checkinVC.isCheckedIn = (_checkinStatus == CHECKIN_STATUS_CHECKED_IN);
    checkinVC.parentTableView = self;
    navC.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.viewController presentModalViewController:navC animated:YES];

}

- (void)refreshFoursquareCell
{
    [self reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)venueCheckinStatusReceived:(BOOL)status forVenue:(NSString *)venue
{
    if ([_foursquareVenue isEqualToString:venue]) {
        if (status) {
            _checkinStatus = CHECKIN_STATUS_CHECKED_IN;
        } else {
            _checkinStatus = CHECKIN_STATUS_NOT_CHECKED_IN;
        }
        [self refreshFoursquareCell];
    }
}

- (void)didReceiveCheckins:(NSArray *)checkins total:(NSInteger)total forVenue:(NSString *)venue
{
    if ([_foursquareVenue isEqualToString:venue]) {
        [_checkedInUsers release];
        _checkedInUsers = [checkins retain];
        
        _checkedInUserCount = total;
    }
    [self refreshFoursquareCell];
}

- (void)eventDetailsDidChange
{
    if (self.mapView && ![self.mapView annotations].count && self.event.coordinate.latitude) {
        [self.mapView addAnnotation:self.event];
        [self.mapView setRegion:MKCoordinateRegionMake(self.event.coordinate, MKCoordinateSpanMake(0.01, 0.01))];
    }
    
    NSString *foursquareVenue = nil;
    
    if ([self.event isKindOfClass:[ScheduleEventWrapper class]]) {
        foursquareVenue = [(ScheduleEventWrapper *)self.event foursquareID];
    } else {
        foursquareVenue = nil;
    }
    
    if (!foursquareVenue || ![_foursquareVenue isEqualToString:foursquareVenue]) {
        [_foursquareVenue release];
        _foursquareVenue = [foursquareVenue retain];
        
        _checkinStatus = CHECKIN_STATUS_UNKNOWN;

        [_checkedInUsers release];
        _checkedInUsers = nil;
    }
    
    [super eventDetailsDidChange];
    
    if (_foursquareVenue && [[KGOSocialMediaController sharedController] isFoursquareLoggedIn]) {
        [[[KGOSocialMediaController sharedController] foursquareEngine] checkUserStatusForVenue:_foursquareVenue
                                                                                       delegate:self];
    }
}

- (NSArray *)sectionForAttendeeInfo
{
    NSMutableArray *attendeeInfo = [NSMutableArray array];

    ScheduleEventWrapper *eventWrapper = (ScheduleEventWrapper *)self.event;
    if ([eventWrapper registrationFee]) {
        if ([eventWrapper isRegistered]) {
            UIImage *image = [UIImage imageWithPathName:@"modules/schedule/badge-confirmed"];
            [attendeeInfo addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                     image, @"image",
                                     @"Registration Confirmed", @"title",
                                     nil]];
            
        } else {
            UIImage *image = [UIImage imageWithPathName:@"modules/schedule/badge-register"];
            NSString *title = [NSString stringWithFormat:@"Registration Required (%@)", [eventWrapper registrationFee]];
            NSString *subtitle = [NSString stringWithFormat:@"Register online at %@", [eventWrapper registrationURL]];
            [attendeeInfo addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                     image, @"image",
                                     title, @"title",
                                     subtitle, @"subtitle",
                                     [eventWrapper registrationURL], @"url",
                                     KGOAccessoryTypeExternal, @"accessory",
                                     nil]];
        }
    }
    
    if (self.event.attendees.count) {
        [attendeeInfo addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSString stringWithFormat:@"%d others attending", self.event.attendees.count], @"title",
                                 KGOAccessoryTypeChevron, @"accessory",
                                 nil]];
    }
    
    return attendeeInfo;
}

#pragma mark table view overrides

- (UIView *)viewForTableHeader
{
    KGONavigationStyle style = [KGO_SHARED_APP_DELEGATE() navigationStyle];
    if (style == KGONavigationStyleTabletSidebar) {
        return nil;
    }
    
    if (!self.headerView) {
        self.headerView = [[[ReunionDetailPageHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 1)] autorelease];
        self.headerView.delegate = self;
        self.headerView.showsBookmarkButton = YES;
    }
    self.headerView.detailItem = self.event;
    
    CGRect frame = self.headerView.frame;
    frame.size.height = 123; // make all headers the same height so it doesn't move when we page between events
    self.headerView.frame = frame;
    
    return self.headerView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_foursquareVenue) {
        if (section == 0) {
            return 1;
        }
        section--;
    }
    
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger num = [super numberOfSectionsInTableView:tableView];
    
    if (_foursquareVenue) {
        num++;
    }
    
    return num;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_foursquareVenue) {
        if (indexPath.section == 0) {
            return tableView.rowHeight;
        }
        indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section - 1];
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_foursquareVenue) {
        if (indexPath.section == 0) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"foursquare"];
            if (!cell) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"foursquare"] autorelease];
            }
            
            if (_checkinStatus == CHECKIN_STATUS_CHECKED_IN) {
                NSInteger count = _checkedInUserCount;
                count--;
                NSString *othersString = @"";
                if (count) {
                    othersString = [NSString stringWithFormat:@" and %d %@", count, count == 1 ? @"other person" : @"others"];
                }
                cell.textLabel.text = [NSString stringWithFormat:@"You%@ are checked in here", othersString, nil];
                cell.imageView.image = [UIImage imageWithPathName:@"modules/foursquare/button-foursquare-checkedin"];
            } else {
                cell.textLabel.text = @"foursquare checkin";
                cell.imageView.image = [UIImage imageWithPathName:@"modules/foursquare/button-foursquare"];
            }
            
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            return cell;
        }
        indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section - 1];
    }
    
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_foursquareVenue) {
        if (indexPath.section == 0) {
            [self foursquareButtonPressed:nil];
            return;
        }
        indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section - 1];
    }
    
    id cellData = [[self.sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    if ([cellData isKindOfClass:[NSDictionary class]]) {    
        NSString *accessory = [cellData objectForKey:@"accessory"];
        if ([accessory isEqualToString:KGOAccessoryTypeChevron]) {
            NSMutableArray *attendees = [NSMutableArray arrayWithCapacity:self.event.attendees.count];
            [self.event.attendees enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                KGOAttendeeWrapper *attendee = (KGOAttendeeWrapper *)obj;
                [attendees addObject:[NSDictionary dictionaryWithObjectsAndKeys:attendee.name, @"display_name", nil]];
            }];
            NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                    self.event.title, @"title",
                                    attendees, @"attendees",
                                    nil];
            [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameItemList forModuleTag:@"schedule" params:params];
            return;
        }
    }
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (void)dealloc
{
    [[[KGOSocialMediaController sharedController] foursquareEngine] disconnectRequestsForDelegate:self];

    [_foursquareVenue release];
    [_checkinHeader release];

    self.mapView.delegate = nil;
    self.mapView = nil;
    
    [super dealloc];
}

#pragma mark MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[ScheduleEventWrapper class]]) {
        ScheduleEventWrapper *event = (ScheduleEventWrapper *)annotation;
        MKAnnotationView *view = [[[MKAnnotationView alloc] initWithAnnotation:event reuseIdentifier:@"hfawue"] autorelease];
        view.canShowCallout = YES;
        view.image = [event annotationImage];
        return view;
    }
    return nil;
}

@end
