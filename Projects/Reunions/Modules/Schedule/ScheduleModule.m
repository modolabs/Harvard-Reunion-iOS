#import "ScheduleModule.h"
#import "ScheduleHomeViewController.h"
#import "ScheduleDetailViewController.h"
#import "ScheduleDataManager.h"
#import "AttendeesTableViewController.h"
#import "KGOSocialMediaController+Foursquare.h"

@implementation ScheduleModule

- (void)launch
{
    if (!self.dataManager) {
        self.dataManager = [[[ScheduleDataManager alloc] init] autorelease];
        self.dataManager.moduleTag = self.tag;
    }
    if (!self.isLaunched) {
        [[KGOSocialMediaController sharedController] startupFoursquare];
        [super launch];
    }
}

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]
        || [pageName isEqualToString:LocalPathPageNameSearch]
        || [pageName isEqualToString:LocalPathPageNameCategoryList]
        ) {
        ScheduleHomeViewController *calendarVC = [[[ScheduleHomeViewController alloc] initWithNibName:@"CalendarHomeViewController"
                                                                                               bundle:nil] autorelease];
        calendarVC.moduleTag = self.tag;
        calendarVC.showsGroups = YES;
        calendarVC.title = NSLocalizedString(@"Events", nil);
        
        if (!self.dataManager) {
            self.dataManager = [[[ScheduleDataManager alloc] init] autorelease];
            self.dataManager.moduleTag = self.tag;
        }
        calendarVC.dataManager = self.dataManager;
        // TODO: we might not need to set the following as long as viewWillAppear is properly invoked
        self.dataManager.delegate = calendarVC;
        
        // requested search path
        NSString *searchText = [params objectForKey:@"q"];
        if (searchText) {
            [calendarVC setSearchTerms:searchText];
        }
        
        // requested category path
        KGOCalendar *calendar = [params objectForKey:@"calendar"];
        calendarVC.currentCalendar = calendar;
        
        vc = calendarVC;
        
    } else if ([pageName isEqualToString:LocalPathPageNameDetail]) {
        ScheduleDetailViewController *detailVC = [[[ScheduleDetailViewController alloc] init] autorelease];
        detailVC.indexPath = [params objectForKey:@"currentIndexPath"];
        detailVC.eventsBySection = [params objectForKey:@"eventsBySection"];
        detailVC.sections = [params objectForKey:@"sections"];
        detailVC.dataManager = self.dataManager;
        vc = detailVC;
        
    } else if ([pageName isEqualToString:LocalPathPageNameItemList]) {
        
        AttendeesTableViewController *attendeesVC = [[[AttendeesTableViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
        attendeesVC.eventTitle = [params objectForKey:@"title"];
        attendeesVC.attendees = [params objectForKey:@"attendees"];
        vc = attendeesVC;
    }
    return vc;
}

@end
