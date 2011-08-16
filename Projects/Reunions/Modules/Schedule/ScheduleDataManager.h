
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import "CalendarDataManager.h"

@class KGORequest;

@interface ScheduleDataManager : CalendarDataManager {
    
    NSMutableDictionary *_allEvents;
    KGORequest *_allEventsRequest;
    
}

- (void)requestAllEvents;

@property (nonatomic, retain) NSDictionary *allEvents;

@end
