#import "ScheduleDetailTableView.h"
#import "KGOSocialMediaController+Foursquare.h"
#import "KGOFoursquareEngine.h"
#import "UIKit+KGOAdditions.h"
#import "ScheduleEventWrapper.h"
#import "Foundation+KGOAdditions.h"
#import "ReunionDetailPageHeaderView.h"
#import "CalendarDataManager.h"
#import "KGOAppDelegate+ModuleAdditions.h"

@implementation ScheduleDetailTableView

- (void)foursquareButtonPressed:(id)sender
{
    [[KGOSocialMediaController sharedController] startupFoursquare];
    [[KGOSocialMediaController sharedController] loginFoursquare];
}

- (void)facebookButtonPressed:(id)sender
{
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

// overriding to accommodate facebook/foursquare buttons
- (void)headerViewFrameDidChange:(KGODetailPageHeaderView *)headerView
{
    CGRect frame = _headerView.frame;
    CGFloat heightForSocialButtons = 0;
    
    if (_facebookButton) {
        frame = _facebookButton.frame;
        frame.origin.x = 10;
        frame.origin.y = _headerView.frame.size.height;
        _facebookButton.frame = frame;
        heightForSocialButtons = _facebookButton.frame.size.height;
    }
    
    if (_foursquareButton) {
        frame = _foursquareButton.frame;
        frame.origin.x = 10;
        if (_facebookButton) {
            frame.origin.x += _facebookButton.frame.size.width;
        }
        _foursquareButton.frame = frame;
        heightForSocialButtons = _foursquareButton.frame.size.height;
    }
    
    if (heightForSocialButtons > 0) {
        frame = _headerView.frame;
        frame.size.height += heightForSocialButtons;
        _headerView.frame = frame;
    }
    
    if (frame.size.height != self.tableHeaderView.frame.size.height) {
        self.tableHeaderView.frame = frame;
    }
    self.tableHeaderView = self.tableHeaderView;
}

- (UIView *)viewForTableHeader
{
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
    
    CGFloat heightForSocialButtons = 0;
    
    if ([_event isKindOfClass:[ScheduleEventWrapper class]] && [(ScheduleEventWrapper *)_event facebookID]) {
        if (!_facebookButton) {
            _facebookButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
            UIImage *image = [UIImage imageWithPathName:@"modules/facebook/button-facebook.png"];
            _facebookButton.frame = CGRectMake(0, 0, image.size.width, image.size.height);
            [_facebookButton setImage:image forState:UIControlStateNormal];
            [_facebookButton addTarget:self action:@selector(facebookButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            heightForSocialButtons = _facebookButton.frame.size.height;
            [containerView addSubview:_facebookButton];
        }
    } else if (_facebookButton) {
        [_facebookButton removeFromSuperview];
        [_facebookButton release];
        _facebookButton = nil;
    }

    if ([_event isKindOfClass:[ScheduleEventWrapper class]] && [(ScheduleEventWrapper *)_event foursquareID]) {
        if (!_foursquareButton) {
            _foursquareButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
            UIImage *image = [UIImage imageWithPathName:@"modules/foursquare/foursquare.jpg"];
            _foursquareButton.frame = CGRectMake(0, 0, image.size.width, image.size.height);
            [_foursquareButton setImage:image forState:UIControlStateNormal];
            [_foursquareButton addTarget:self action:@selector(foursquareButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            heightForSocialButtons = _foursquareButton.frame.size.height;
            [containerView addSubview:_foursquareButton];
        }
    } else if (_foursquareButton) {
        [_foursquareButton removeFromSuperview];
        [_foursquareButton release];
        _foursquareButton = nil;
    }

    if (heightForSocialButtons > 0) {
        CGRect frame = containerView.frame;
        frame.size.height += heightForSocialButtons;
        containerView.frame = frame;
    }
    
    return containerView;
}

- (void)dealloc
{
    [_facebookButton release];
    [_foursquareButton release];
    [super dealloc];
}

@end
