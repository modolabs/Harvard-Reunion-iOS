#import "ScheduleModule.h"
#import "ScheduleHomeViewController.h"
#import "ScheduleDetailViewController.h"
#import "ScheduleDataManager.h"
#import "AttendeesTableViewController.h"
#import "FoursquareCheckinViewController.h"
#import "KGOSocialMediaController.h"
#import "ScheduleHomeViewController-iPad.h"

@implementation ScheduleModule

- (void)launch
{
    if (!self.dataManager) {
        self.dataManager = [[[ScheduleDataManager alloc] init] autorelease];
        self.dataManager.moduleTag = self.tag;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didLogout:) name:KGODidLogoutNotification object:nil];
    }
    if (!self.isLaunched) {
        [[KGOSocialMediaController foursquareService] startup];
        [super launch];
    }
}

- (void)didLogout:(NSNotification *)aNotification
{
    // release the old data manager which is referncing expired core data objects
    // TODO: fix this in kurogo if needed
    self.dataManager = [[[ScheduleDataManager alloc] init] autorelease];
    self.dataManager.moduleTag = self.tag;
}

- (NSArray *)registeredPageNames {
    return [NSArray arrayWithObjects:
            LocalPathPageNameHome, LocalPathPageNameSearch, LocalPathPageNameDetail,
            LocalPathPageNameCategoryList, LocalPathPageNameItemList, @"foursquareCheckins", nil];
}

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]
        || [pageName isEqualToString:LocalPathPageNameSearch]
        || [pageName isEqualToString:LocalPathPageNameCategoryList]
    ) {
        ScheduleHomeViewController *scheduleVC = nil;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            scheduleVC = [[[ScheduleHomeViewController alloc] initWithNibName:@"CalendarHomeViewController"
                                                                       bundle:nil] autorelease];
        } else {
            scheduleVC = [[[ScheduleHomeViewController_iPad alloc] initWithNibName:@"CalendarHomeViewController"
                                                                            bundle:nil] autorelease];
        }
        
        scheduleVC.moduleTag = self.tag;
        scheduleVC.showsGroups = YES;
        scheduleVC.title = NSLocalizedString(@"Schedule", nil);
        
        if (!self.dataManager) {
            self.dataManager = [[[ScheduleDataManager alloc] init] autorelease];
            self.dataManager.moduleTag = self.tag;
        }
        scheduleVC.dataManager = self.dataManager;
        // TODO: we might not need to set the following as long as viewWillAppear is properly invoked
        self.dataManager.delegate = scheduleVC;
        
        // requested search path
        NSString *searchText = [params objectForKey:@"q"];
        if (searchText) {
            [scheduleVC setSearchTerms:searchText];
        }
        
        // requested category path
        KGOCalendar *calendar = [params objectForKey:@"calendar"];
        scheduleVC.currentCalendar = calendar;
        
        vc = scheduleVC;
        
    } else if ([pageName isEqualToString:LocalPathPageNameDetail]) {
        ScheduleDetailViewController *detailVC = [[[ScheduleDetailViewController alloc] init] autorelease];
        detailVC.indexPath = [params objectForKey:@"currentIndexPath"];
        detailVC.eventsBySection = [params objectForKey:@"eventsBySection"];
        detailVC.sections = [params objectForKey:@"sections"];
        detailVC.dataManager = self.dataManager;
        vc = detailVC;
        
    } else if ([pageName isEqualToString:LocalPathPageNameItemList]) {
        
        AttendeesTableViewController *attendeesVC = [[[AttendeesTableViewController alloc] init] autorelease];
        attendeesVC.eventTitle = [params objectForKey:@"title"];
        attendeesVC.attendees = [params objectForKey:@"attendees"];
        vc = attendeesVC;
        
    } else if ([pageName isEqualToString:@"foursquareCheckins"]) {
        
        FoursquareCheckinViewController *foursquareVC = [[[FoursquareCheckinViewController alloc]  initWithStyle:UITableViewStyleGrouped] autorelease];
        foursquareVC.eventTitle = [params objectForKey:@"eventTitle"];
        foursquareVC.checkinData = [params objectForKey:@"checkinData"];
        foursquareVC.checkedInUserCount = [(NSNumber *)[params objectForKey:@"checkedInUserCount"] integerValue];
        foursquareVC.venue = [params objectForKey:@"venue"];
        foursquareVC.isCheckedIn = [(NSNumber *)[params objectForKey:@"isCheckedIn"] boolValue];
        foursquareVC.parentTableView = [params objectForKey:@"parentTableView"];

        vc = foursquareVC;
    }
    return vc;
}

@end
