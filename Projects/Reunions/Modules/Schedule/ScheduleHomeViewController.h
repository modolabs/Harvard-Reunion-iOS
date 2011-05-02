#import "CalendarHomeViewController.h"

@class ScheduleEventWrapper;

@interface ScheduleHomeViewController : CalendarHomeViewController {

}

- (void)addToMyEvents:(ScheduleEventWrapper *)event;
- (void)removeFromMyEvents:(ScheduleEventWrapper *)event;

@end
