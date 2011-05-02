#import "CalendarDataManager.h"

@class KGORequest;

@interface ScheduleDataManager : CalendarDataManager {
    
    NSMutableDictionary *_allEvents;
    KGORequest *_allEventsRequest;
    
}

- (void)requestAllEvents;

@property (nonatomic, retain) NSDictionary *allEvents;

@end
