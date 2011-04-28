#import "ScheduleDetailTableView.h"
#import "UIKit+KGOAdditions.h"
#import "ScheduleEventWrapper.h"
#import "Foundation+KGOAdditions.h"
#import "ReunionDetailPageHeaderView.h"
#import "CalendarDataManager.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "FoursquareCheckinViewController.h"
#import "KGOSocialMediaController.h"

#define CHECKIN_STATUS_CHECKED_IN 438
#define CHECKIN_STATUS_NOT_CHECKED_IN 41
#define CHECKIN_STATUS_UNKNOWN 768


@implementation ScheduleDetailTableView

@synthesize mapView;

- (void)foursquareButtonPressed:(id)sender
{
    if (![[KGOSocialMediaController foursquareService] isSignedIn]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(presentFoursquareCheckinController)
                                                     name:FoursquareDidLoginNotification
                                                   object:nil];
        
        [[KGOSocialMediaController foursquareService] signin];
        
    } else {
        [self presentFoursquareCheckinController];
    }
}

- (void)presentFoursquareCheckinController
{
    if ([(UIViewController *)self.viewController modalViewController]) {
        [self performSelector:@selector(presentFoursquareCheckinController) withObject:nil afterDelay:0.1];
        return;
    }
    
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
    navC.navigationBar.barStyle = [[KGOTheme sharedTheme] defaultNavBarStyle];
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
    [super eventDetailsDidChange];
    
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
    
    if (_foursquareVenue && [[KGOSocialMediaController foursquareService] isSignedIn]) {
        [[[KGOSocialMediaController foursquareService] foursquareEngine] checkUserStatusForVenue:_foursquareVenue
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
            NSString *subtitle = [eventWrapper registrationURL] ?
                [NSString stringWithFormat:@"Register online at %@", [eventWrapper registrationURL]] : nil;
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
    
    // time
    NSString *dateString = [self.dataManager mediumDateStringFromDate:_event.startDate];
    NSString *timeString = nil;
    if (self.event.endDate) {
        timeString = [NSString stringWithFormat:@"%@\n%@-%@",
                      dateString,
                      [self.dataManager shortTimeStringFromDate:self.event.startDate],
                      [self.dataManager shortTimeStringFromDate:self.event.endDate]];
    } else {
        timeString = [NSString stringWithFormat:@"%@\n%@",
                      dateString,
                      [self.dataManager shortTimeStringFromDate:self.event.startDate]];
    }
    self.headerView.subtitleLabel.text = timeString;
    
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
    id cellData = [[_sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    if ([cellData isKindOfClass:[NSDictionary class]]) {
        NSString *title = [cellData objectForKey:@"title"];
        NSString *subtitle = [cellData objectForKey:@"subtitle"];
        NSString *accessory = [cellData objectForKey:@"accessory"];
        UIImage *image = [cellData objectForKey:@"image"];

        // adjust for icon, padding and accessory
        CGFloat width = tableView.frame.size.width - 20 - (image ? 34 : 0) - (accessory != KGOAccessoryTypeNone ? 34 : 0); 
        CGFloat height = 22;
        
        UIFont *titleFont = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListTitle];
        CGSize titleSize = [title sizeWithFont:titleFont
                             constrainedToSize:CGSizeMake(width, 1000)
                                 lineBreakMode:UILineBreakModeWordWrap];
        height += titleSize.height;
        
        if (subtitle && [subtitle length]) {
            UIFont *subtitleFont = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListSubtitle];
            CGSize subtitleSize = [title sizeWithFont:subtitleFont
                                    constrainedToSize:CGSizeMake(width, 1000)
                                        lineBreakMode:UILineBreakModeWordWrap];
            height += subtitleSize.height + 2;
        }
        
        return height;
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
            
            cell.accessoryView = [[KGOTheme sharedTheme] accessoryViewForType:KGOAccessoryTypeChevron];
            
            return cell;
        }
        indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section - 1];
        
    }
    
    id cellData = [[_sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    if ([cellData isKindOfClass:[NSDictionary class]]) {
        NSString *title = [cellData objectForKey:@"title"];
        NSString *subtitle = [cellData objectForKey:@"subtitle"];
        NSString *accessory = [cellData objectForKey:@"accessory"];
        UIImage *image = [cellData objectForKey:@"image"];
        
        UITableViewCellStyle style = UITableViewCellStyleDefault;
        if (subtitle && [subtitle length]) {
            style = UITableViewCellStyleSubtitle;
        }
        NSString *cellIdentifier = [NSString stringWithFormat:@"%d", style];
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!cell) {
            cell = [[[UITableViewCell alloc] initWithStyle:style reuseIdentifier:cellIdentifier] autorelease];
        }
        
        if (accessory && ![accessory isEqualToString:KGOAccessoryTypeNone]) {
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            
        } else {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.accessoryView = [[KGOTheme sharedTheme] accessoryViewForType:accessory];
        if (image) {
            cell.imageView.image = image;
        }

        NSInteger titleTag = 50;
        NSInteger subtitleTag = 51;
        
        // adjust for icon, padding and accessory
        CGFloat width = tableView.frame.size.width - 20 - (image ? 34 : 0) - (accessory != KGOAccessoryTypeNone ? 34 : 0); 
        CGFloat x = image ? 44 : 10;
        CGFloat y = 10;
        
        UIFont *titleFont = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListTitle];
        UILabel *titleLabel = (UILabel *)[cell.contentView viewWithTag:titleTag];
        if (!titleLabel) {
            titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(x, y, width, titleFont.lineHeight)] autorelease];
            titleLabel.font = titleFont;
            titleLabel.backgroundColor = [UIColor clearColor];
            titleLabel.numberOfLines = 10;
            titleLabel.lineBreakMode = UILineBreakModeWordWrap;
            titleLabel.tag = titleTag;
        } 
        CGSize titleSize = [title sizeWithFont:titleFont
                             constrainedToSize:CGSizeMake(width, titleFont.lineHeight * 10)
                                 lineBreakMode:UILineBreakModeWordWrap];
        CGRect titleFrame = titleLabel.frame;
        titleFrame.size.height = titleSize.height;
        titleFrame.origin.x = x;
        titleLabel.frame = titleFrame;
        titleLabel.text = title;
        [cell.contentView addSubview:titleLabel];
        y += titleSize.height + 1;
        
        if (subtitle && [subtitle length]) {
            UIFont *subtitleFont = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListSubtitle];
            UILabel *subtitleLabel = (UILabel *)[cell.contentView viewWithTag:subtitleTag];
            if (!subtitleLabel) {
                subtitleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(x, y, width, subtitleFont.lineHeight)] autorelease];
                subtitleLabel.font = subtitleFont;
                subtitleLabel.backgroundColor = [UIColor clearColor];
                subtitleLabel.numberOfLines = 10;
                subtitleLabel.lineBreakMode = UILineBreakModeWordWrap;
                subtitleLabel.tag = subtitleTag;
            }
            CGSize subtitleSize = [title sizeWithFont:subtitleFont
                                    constrainedToSize:CGSizeMake(width, subtitleFont.lineHeight * 10)
                                        lineBreakMode:UILineBreakModeWordWrap];
            CGRect subtitleFrame = subtitleLabel.frame;
            subtitleFrame.size.height = subtitleSize.height;
            subtitleFrame.origin.x = x;
            subtitleFrame.origin.y = y;
            subtitleLabel.frame = subtitleFrame;
            subtitleLabel.text = subtitle;
            [cell.contentView addSubview:subtitleLabel];
        }
        
        return cell;
    }
    
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_foursquareVenue) {
        if (indexPath.section == 0) {
            [self foursquareButtonPressed:nil];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            return;
        }
        indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section - 1];
    }

    id cellData = [[_sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    if ([cellData isKindOfClass:[NSDictionary class]]) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
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
    [[[KGOSocialMediaController foursquareService] foursquareEngine] disconnectRequestsForDelegate:self];

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
