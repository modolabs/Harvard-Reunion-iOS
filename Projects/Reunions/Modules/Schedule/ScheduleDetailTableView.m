#import "ScheduleDetailTableView.h"
#import "KGOSocialMediaController+Foursquare.h"
#import "KGOFoursquareEngine.h"
#import "UIKit+KGOAdditions.h"
#import "ScheduleEventWrapper.h"
#import "Foundation+KGOAdditions.h"
#import "ReunionDetailPageHeaderView.h"
#import "CalendarDataManager.h"
#import "KGOAppDelegate+ModuleAdditions.h"

#define CHECKIN_STATUS_CHECKED_IN 438
#define CHECKIN_STATUS_NOT_CHECKED_IN 41
#define CHECKIN_STATUS_UNKNOWN 768


@implementation ScheduleDetailTableView

@synthesize mapView;

- (void)foursquareButtonPressed:(id)sender
{
    if (![[KGOSocialMediaController sharedController] isFoursquareLoggedIn]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(checkinFoursquarePlace)
                                                     name:FoursquareDidLoginNotification
                                                   object:nil];
        [[KGOSocialMediaController sharedController] loginFoursquare];
        
    } else {
        [self checkinFoursquarePlace];
    }
}

- (void)checkinFoursquarePlace
{
    if (_foursquareVenue) {    
        [[[KGOSocialMediaController sharedController] foursquareEngine] checkinVenue:_foursquareVenue
                                                                            delegate:self];
    }
}

- (void)venueCheckinDidSucceed:(NSString *)venue
{
    _checkinStatus = CHECKIN_STATUS_CHECKED_IN;
    [self setupFoursquareButton];
}

- (void)venueCheckinStatusReceived:(BOOL)status forVenue:(NSString *)venue
{
    if ([_foursquareVenue isEqualToString:venue]) {
        if (status) {
            _checkinStatus = CHECKIN_STATUS_CHECKED_IN;
        } else {
            _checkinStatus = CHECKIN_STATUS_NOT_CHECKED_IN;
        }
        [self setupFoursquareButton];
    }
}

- (void)eventDetailsDidChange
{
    [super eventDetailsDidChange];
    
    if (self.mapView && ![self.mapView annotations].count && _event.coordinate.latitude) {
        [self.mapView addAnnotation:_event];
        [self.mapView setRegion:MKCoordinateRegionMake(_event.coordinate, MKCoordinateSpanMake(0.01, 0.01))];
    }
    
    NSString *foursquareVenue = nil;
    
    if ([_event isKindOfClass:[ScheduleEventWrapper class]]) {
        foursquareVenue = [(ScheduleEventWrapper *)_event foursquareID];
    } else {
        foursquareVenue = nil;
    }
    
    if (![_foursquareVenue isEqualToString:foursquareVenue]) {
        [_foursquareVenue release];
        _foursquareVenue = [foursquareVenue retain];
        _checkinStatus = CHECKIN_STATUS_UNKNOWN;
    }
    
    // TODO: this override calls -reloadData twice, once in super and once in
    // -setupFoursquareButton. we don't have many rows in this table, but it
    // would be better to clean up our functions so we don't call -reloadData
    // unnecessarily.
    [self setupFoursquareButton];
}

- (void)setupFoursquareButton
{
    NSInteger foursquareButtonTag = 287;
    UIButton *foursquareButton = (UIButton *)[_checkinHeader viewWithTag:foursquareButtonTag];
    
    if (_checkinStatus == CHECKIN_STATUS_UNKNOWN && [[KGOSocialMediaController sharedController] isFoursquareLoggedIn]) {
        [foursquareButton setImage:[UIImage imageWithPathName:@"modules/foursquare/button-foursquare"]
                          forState:UIControlStateNormal];
        
        [[[KGOSocialMediaController sharedController] foursquareEngine] checkUserStatusForVenue:_foursquareVenue
                                                                                       delegate:self];
        return;
    }

    if (_foursquareVenue) {
        if (!_checkinHeader) {
            NSString *checkInString = @"Check in:";
            UIFont *font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyBodyText];
            CGSize size = [checkInString sizeWithFont:font];
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, size.width, size.height)];
            label.text = checkInString;
            label.font = font;
            label.textColor = [UIColor whiteColor];
            label.backgroundColor = [UIColor clearColor];
            
            foursquareButton = [UIButton buttonWithType:UIButtonTypeCustom];
            foursquareButton.tag = foursquareButtonTag;
            UIImage *image = [UIImage imageWithPathName:@"modules/foursquare/button-foursquare"];
            [foursquareButton setImage:image
                              forState:UIControlStateNormal];
            [foursquareButton setTitle:[KGOSocialMediaController localizedNameForService:KGOSocialMediaTypeFoursquare]
                              forState:UIControlStateNormal];
            [foursquareButton addTarget:self
                                 action:@selector(foursquareButtonPressed:)
                       forControlEvents:UIControlEventTouchUpInside];
            foursquareButton.titleLabel.font = font;
            foursquareButton.titleEdgeInsets = UIEdgeInsetsMake(0, 5, 0, 0);
            
            CGFloat width = [foursquareButton.titleLabel.text sizeWithFont:foursquareButton.titleLabel.font].width + 5;
            foursquareButton.frame = CGRectMake(label.frame.size.width + 20, 0,
                                                image.size.width + width + 10,
                                                image.size.height);
            
            _checkinHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, image.size.height + 3)];
            
            [_checkinHeader addSubview:label];
            [_checkinHeader addSubview:foursquareButton];

        }
        
        if (_checkinStatus == CHECKIN_STATUS_CHECKED_IN) {
            [foursquareButton setImage:[UIImage imageWithPathName:@"modules/foursquare/button-foursquare-checkedin"]
                              forState:UIControlStateNormal];
        } else {
            [foursquareButton setImage:[UIImage imageWithPathName:@"modules/foursquare/button-foursquare"]
                              forState:UIControlStateNormal];
        }
        
    } else if (_checkinHeader) {
        [_checkinHeader release];
        _checkinHeader = nil;
    }
    
    [self reloadData];
}

- (NSArray *)sectionForAttendeeInfo
{
    NSMutableArray *attendeeInfo = [NSMutableArray array];

    ScheduleEventWrapper *eventWrapper = (ScheduleEventWrapper *)_event;
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
    
    if (_event.attendees.count) {
        [attendeeInfo addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSString stringWithFormat:@"%d others attending", _event.attendees.count], @"title",
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
    return [super viewForTableHeader];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (_checkinHeader && section == 0) {
        return _checkinHeader;
        
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (_checkinHeader && section == 0) {
        return _checkinHeader.frame.size.height;
    }
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id cellData = [[_sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    if ([cellData isKindOfClass:[NSDictionary class]]) {    
        NSString *accessory = [cellData objectForKey:@"accessory"];
        if ([accessory isEqualToString:KGOAccessoryTypeChevron]) {
            NSMutableArray *attendees = [NSMutableArray arrayWithCapacity:_event.attendees.count];
            [_event.attendees enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                KGOAttendeeWrapper *attendee = (KGOAttendeeWrapper *)obj;
                [attendees addObject:[NSDictionary dictionaryWithObjectsAndKeys:attendee.name, @"display_name", nil]];
            }];
            NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                    _event.title, @"title",
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
