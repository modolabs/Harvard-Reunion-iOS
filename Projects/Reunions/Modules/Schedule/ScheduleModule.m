#import "ScheduleModule.h"
#import "ScheduleHomeViewController.h"
#import "CalendarDetailViewController.h"

@implementation ScheduleModule

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        ScheduleHomeViewController *calendarVC = [[[ScheduleHomeViewController alloc] initWithNibName:@"CalendarHomeViewController"
                                                                                               bundle:nil] autorelease];
        calendarVC.moduleTag = self.tag;
        vc = calendarVC;
        
    } else if ([pageName isEqualToString:LocalPathPageNameSearch]) {
        ScheduleHomeViewController *calendarVC = [[[ScheduleHomeViewController alloc] initWithNibName:@"CalendarHomeViewController"
                                                                                               bundle:nil] autorelease];
        calendarVC.moduleTag = self.tag;
        
        NSString *searchText = [params objectForKey:@"q"];
        if (searchText) {
            [calendarVC setSearchTerms:searchText];
        }
        
        vc = calendarVC;
        
    } else if ([pageName isEqualToString:LocalPathPageNameDetail]) {
        CalendarDetailViewController *detailVC = [[[CalendarDetailViewController alloc] init] autorelease];
        detailVC.indexPath = [params objectForKey:@"currentIndexPath"];
        detailVC.eventsBySection = [params objectForKey:@"eventsBySection"];
        detailVC.sections = [params objectForKey:@"sections"];
        vc = detailVC;
        
    } else if ([pageName isEqualToString:LocalPathPageNameCategoryList]) {
        
    } else if ([pageName isEqualToString:LocalPathPageNameItemList]) {
        
    }
    return vc;
}

@end
