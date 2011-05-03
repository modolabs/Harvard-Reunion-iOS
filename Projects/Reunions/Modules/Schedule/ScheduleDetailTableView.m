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
    if ([[KGOSocialMediaController foursquareService] isSignedIn]) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:FoursquareDidLoginNotification
                                                      object:nil];
    }
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            self, @"parentTableView",
                            self.event.title, @"eventTitle",
                            [NSNumber numberWithInt:_checkedInUserCount], @"checkedInUserCount",
                            [NSNumber numberWithBool:(_checkinStatus == CHECKIN_STATUS_CHECKED_IN)], @"isCheckedIn",
                            _foursquareVenue, @"venue",
                            _checkedInUsers, @"checkinData", // last because it can be nil
                            nil];
    [KGO_SHARED_APP_DELEGATE() showPage:@"foursquareCheckins" forModuleTag:@"schedule" params:params];
}

- (void)refreshFoursquareCell
{
    //[self beginUpdates];
    [self reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
    //[self endUpdates];
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

- (void)venueCheckinStatusFailed:(NSString *)venue withMessage:(NSString *)message
{
    // Currently we don't try to handle this.  Just leave the UI as is and when they click on 
    // the foursquare link the FoursquareCheckinViewController will display an error
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
#if defined(USE_MOBILE_DEV) || defined(USE_MOBILE_TEST) || defined(USE_MOBILE_STAGE)
        // Fake that the event is happening now so we can test the foursquare checkin
        NSDate *now = [NSDate dateWithTimeInterval: 60 sinceDate:_event.startDate];
#else
        // Production behavior
        NSDate *now = [NSDate date];
#endif
        NSDate *begin = [NSDate dateWithTimeInterval: -900 sinceDate:_event.startDate];
        NSDate *end = [NSDate dateWithTimeInterval:  900 sinceDate:_event.endDate];
        
        if ([now compare:begin] != NSOrderedAscending &&  // on or after start
            [now compare:end]   != NSOrderedDescending) { // on or before end
            
            foursquareVenue = [(ScheduleEventWrapper *)self.event foursquareID];
        }
    }
    
    if (!foursquareVenue || ![_foursquareVenue isEqualToString:foursquareVenue]) {
        [_foursquareVenue release];
        _foursquareVenue = [foursquareVenue retain];
        
        _checkinStatus = CHECKIN_STATUS_UNKNOWN;

        [_checkedInUsers release];
        _checkedInUsers = nil;
        _checkedInUserCount = 0;
    }
    
    if (_foursquareVenue && [[KGOSocialMediaController foursquareService] isSignedIn]) {
        [[[KGOSocialMediaController foursquareService] foursquareEngine] checkUserStatusForVenue:_foursquareVenue
                                                                                        delegate:self];
    }
    
    [super eventDetailsDidChange];
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

#pragma mark foursquare cell

- (NSString *)titleForFoursquareCell 
{
    NSString *title = nil;
    
    if (_foursquareVenue) {
        if (_checkinStatus == CHECKIN_STATUS_CHECKED_IN) {
            NSInteger otherCount = _checkedInUserCount - 1; // don't count user
            
            NSString *othersString = @"";
            if (otherCount > 0) {
                othersString = [NSString stringWithFormat:@" and %d %@", otherCount, 
                                otherCount == 1 ? @"other person" : @"other people"];
            }
            title = [NSString stringWithFormat:@"You%@ are here", othersString, nil];
            
        } else {
            title = @"foursquare checkin";
        }
    }
    
    return title;
}

- (NSString *)subtitleForFoursquareCell
{
    NSString *subtitle = nil;
    
    if (_foursquareVenue) {
        if (_checkinStatus != CHECKIN_STATUS_CHECKED_IN) {
            NSInteger otherCount = _checkedInUserCount;
            
            if (otherCount > 0) {
                subtitle = [NSString stringWithFormat:@"%d %@", otherCount, 
                            otherCount == 1 ? @"other person is here" : @"other people are here"];
            }
        }
        
    }
    
    return subtitle;
}

- (UIImage *)imageForFoursquareCell
{
    UIImage *image = nil;
    
    if (_foursquareVenue) {
        if (_checkinStatus == CHECKIN_STATUS_CHECKED_IN) {
            image = [UIImage imageWithPathName:@"modules/foursquare/button-foursquare-checkedin"];
            
        } else {
            image = [UIImage imageWithPathName:@"modules/foursquare/button-foursquare"];
        }        
    }
    
    return image;
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
    NSString *title = nil;
    NSString *subtitle = nil;
    NSString *accessory = KGOAccessoryTypeNone;
    UIImage *image = nil;
    
    if (_foursquareVenue) {
        if (indexPath.section == 0) {
            title = [self titleForFoursquareCell];
            subtitle = [self subtitleForFoursquareCell];
            image = [self imageForFoursquareCell];
            accessory = KGOAccessoryTypeChevron;
            
        }
        indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section - 1];
    }

    if (!title) {
        id cellData = [[_sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        if ([cellData isKindOfClass:[NSDictionary class]]) {
            title = [cellData objectForKey:@"title"];
            subtitle = [cellData objectForKey:@"subtitle"];
            accessory = [cellData objectForKey:@"accessory"];
            image = [cellData objectForKey:@"image"];
        }
    }
    
    if (title) {
        // adjust for icon, padding and accessory
        CGFloat width = tableView.frame.size.width - 20 - (image ? 39 : 0) - (accessory != KGOAccessoryTypeNone ? 39 : 0); 
        CGFloat height = 22;
        
        UIFont *titleFont = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListTitle];
        CGSize titleSize = [title sizeWithFont:titleFont
                             constrainedToSize:CGSizeMake(width, titleFont.lineHeight * 10)
                                 lineBreakMode:UILineBreakModeTailTruncation];
        height += titleSize.height;
        
        if (subtitle && [subtitle length]) {
            UIFont *subtitleFont = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListSubtitle];
            CGSize subtitleSize = [subtitle sizeWithFont:subtitleFont
                                    constrainedToSize:CGSizeMake(width, subtitleFont.lineHeight * 10)
                                        lineBreakMode:UILineBreakModeTailTruncation];
            height += subtitleSize.height + 2;
        }
        
        return height;
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *title = nil;
    NSString *subtitle = nil;
    NSString *accessory = KGOAccessoryTypeNone;
    UIImage *image = nil;

    
    if (_foursquareVenue) {
        if (indexPath.section == 0) {
            title = [self titleForFoursquareCell];
            subtitle = [self subtitleForFoursquareCell];
            image = [self imageForFoursquareCell];
            accessory = KGOAccessoryTypeChevron;
            
        }
        indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section - 1];
    }

    if (!title) {
        id cellData = [[_sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        if ([cellData isKindOfClass:[NSDictionary class]]) {
            title = [cellData objectForKey:@"title"];
            subtitle = [cellData objectForKey:@"subtitle"];
            accessory = [cellData objectForKey:@"accessory"];
            image = [cellData objectForKey:@"image"];
        }
    }

    if (title) {
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
        cell.imageView.image = image;
        cell.autoresizingMask = UIViewAutoresizingFlexibleHeight;

        NSInteger titleTag = 50;
        NSInteger subtitleTag = 51;
        
        // adjust for icon, padding and accessory
        CGFloat width = tableView.frame.size.width - 20 - (image ? 39 : 0) - (accessory != KGOAccessoryTypeNone ? 39 : 0); 
        CGFloat x = image ? 44 : 10;
        CGFloat y = 10;
        
        UIFont *titleFont = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListTitle];
        UILabel *titleLabel = (UILabel *)[cell.contentView viewWithTag:titleTag];
        if (!titleLabel) {
            titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(x, y, width, titleFont.lineHeight)] autorelease];
            titleLabel.font = titleFont;
            titleLabel.backgroundColor = [UIColor clearColor];
            titleLabel.numberOfLines = 10;
            titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
            titleLabel.tag = titleTag;
            [cell.contentView addSubview:titleLabel];
        } 
        CGSize titleSize = [title sizeWithFont:titleFont
                             constrainedToSize:CGSizeMake(width, titleFont.lineHeight * 10)
                                 lineBreakMode:UILineBreakModeTailTruncation];
        CGRect titleFrame = titleLabel.frame;
        titleFrame.size.width = width;
        titleFrame.size.height = titleSize.height;
        titleFrame.origin.x = x;
        titleLabel.frame = titleFrame;
        titleLabel.text = title;
        y += titleSize.height + 1;
        
        if (subtitle && [subtitle length]) {
            UIFont *subtitleFont = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListSubtitle];
            UILabel *subtitleLabel = (UILabel *)[cell.contentView viewWithTag:subtitleTag];
            if (!subtitleLabel) {
                subtitleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(x, y, width, subtitleFont.lineHeight)] autorelease];
                subtitleLabel.font = subtitleFont;
                subtitleLabel.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyNavListSubtitle];
                subtitleLabel.backgroundColor = [UIColor clearColor];
                subtitleLabel.numberOfLines = 10;
                subtitleLabel.lineBreakMode = UILineBreakModeTailTruncation;
                subtitleLabel.tag = subtitleTag;
                [cell.contentView addSubview:subtitleLabel];
            }
            CGSize subtitleSize = [subtitle sizeWithFont:subtitleFont
                                    constrainedToSize:CGSizeMake(width, subtitleFont.lineHeight * 10)
                                        lineBreakMode:UILineBreakModeTailTruncation];
            CGRect subtitleFrame = subtitleLabel.frame;
            subtitleFrame.size.width = width;
            subtitleFrame.size.height = subtitleSize.height;
            subtitleFrame.origin.x = x;
            subtitleFrame.origin.y = y;
            subtitleLabel.frame = subtitleFrame;
            subtitleLabel.text = subtitle;
        }
        
        return cell;
    }
    
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_foursquareVenue) {
        if (indexPath.section == 0) {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            [self foursquareButtonPressed:nil];
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
