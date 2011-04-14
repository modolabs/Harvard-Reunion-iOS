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
    self.tableHeaderView = [self viewForTableHeader];
}

- (void)venueCheckinStatusReceived:(BOOL)status forVenue:(NSString *)venue
{
    if ([_foursquareVenue isEqualToString:venue]) {
        if (status) {
            _checkinStatus = CHECKIN_STATUS_CHECKED_IN;
        } else {
            _checkinStatus = CHECKIN_STATUS_NOT_CHECKED_IN;
        }
        self.tableHeaderView = [self viewForTableHeader];
    }
}

- (void)setupFoursquareButton
{
    if (_checkinStatus == CHECKIN_STATUS_UNKNOWN && [[KGOSocialMediaController sharedController] isFoursquareLoggedIn]) {
        [_foursquareButton setImage:[UIImage imageWithPathName:@"modules/foursquare/button-foursquare"]
                           forState:UIControlStateNormal];
        
        [[[KGOSocialMediaController sharedController] foursquareEngine] checkUserStatusForVenue:_foursquareVenue
                                                                                       delegate:self];
        return;
    }

    if (_foursquareVenue) {
        if (!_foursquareButton) {
            NSString *checkInString = @"Check in:";
            UIFont *font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyBodyText];
            CGSize size = [checkInString sizeWithFont:font];
            _checkinLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, size.width, size.height)];
            _checkinLabel.text = checkInString;
            _checkinLabel.font = font;
            _checkinLabel.textColor = [UIColor whiteColor];
            _checkinLabel.backgroundColor = [UIColor clearColor];
            
            _foursquareButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
            UIImage *image = [UIImage imageWithPathName:@"modules/foursquare/button-foursquare"];
            [_foursquareButton setImage:image
                               forState:UIControlStateNormal];
            [_foursquareButton setTitle:[KGOSocialMediaController localizedNameForService:KGOSocialMediaTypeFoursquare]
                               forState:UIControlStateNormal];
            [_foursquareButton addTarget:self
                                  action:@selector(foursquareButtonPressed:)
                        forControlEvents:UIControlEventTouchUpInside];
            
            CGFloat width = [_foursquareButton.titleLabel.text sizeWithFont:_foursquareButton.titleLabel.font].width;
            _foursquareButton.frame = CGRectMake(_checkinLabel.frame.size.width + 20, 0,
                                                 image.size.width + width + 10,
                                                 image.size.height);
        }
        
        if (_checkinStatus == CHECKIN_STATUS_CHECKED_IN) {
            [_foursquareButton setImage:[UIImage imageWithPathName:@"modules/foursquare/button-foursquare-checkedin"]
                               forState:UIControlStateNormal];
        } else {
            [_foursquareButton setImage:[UIImage imageWithPathName:@"modules/foursquare/button-foursquare"]
                               forState:UIControlStateNormal];
        }
        
    } else if (_foursquareButton) {
        [_foursquareButton removeFromSuperview];
        [_foursquareButton release];
        _foursquareButton = nil;
    }
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

// overriding to accommodate foursquare buttons
- (void)headerViewFrameDidChange:(KGODetailPageHeaderView *)headerView
{
    CGRect frame = _headerView.frame;
    
    if (_foursquareButton) {
        frame = _foursquareButton.frame;
        frame.origin.y = _headerView.frame.size.height;
        _foursquareButton.frame = frame;
        
        frame = _checkinLabel.frame;
        frame.origin.y = _foursquareButton.frame.origin.y;
        _checkinLabel.frame = frame;
        
        frame = _headerView.frame;
        frame.size.height += _foursquareButton.frame.size.height;
        _headerView.frame = frame;
    }
    
    if (frame.size.height != self.tableHeaderView.frame.size.height) {
        self.tableHeaderView.frame = frame;
    }
    self.tableHeaderView = self.tableHeaderView;
}

- (UIView *)viewForTableHeader
{
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
    
    if (!_headerView) {
        _headerView = [[ReunionDetailPageHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 1)];
        _headerView.delegate = self;
        _headerView.showsBookmarkButton = YES;
    }
    _headerView.detailItem = self.event;
    
    UIView *containerView = [[[UIView alloc] initWithFrame:_headerView.frame] autorelease];
    [containerView addSubview:_headerView];

    // time
    NSString *dateString = [self.dataManager mediumDateStringFromDate:_event.startDate];
    NSString *timeString = nil;
    if (_event.endDate) {
        timeString = [NSString stringWithFormat:@"%@\n%@-%@",
                      dateString,
                      [self.dataManager shortTimeStringFromDate:_event.startDate],
                      [self.dataManager shortTimeStringFromDate:_event.endDate]];
    } else {
        timeString = [NSString stringWithFormat:@"%@\n%@",
                      dateString,
                      [self.dataManager shortTimeStringFromDate:_event.startDate]];
    }
    _headerView.subtitleLabel.text = timeString;

    [self setupFoursquareButton];
    
    if (_foursquareButton) {
        [containerView addSubview:_checkinLabel];
        [containerView addSubview:_foursquareButton];
        CGRect frame = containerView.frame;
        frame.size.height += _foursquareButton.frame.size.height;
        containerView.frame = frame;
    }
    
    return containerView;
}

- (void)dealloc
{
    [_foursquareButton release];
    [super dealloc];
}

@end
