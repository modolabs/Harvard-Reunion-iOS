
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import "MapModule.h"

extern NSString * const EventMapCategoryName;

@class ScheduleDataManager;

@interface ReunionMapModule : MapModule {
    ScheduleDataManager *scheduleManager;

}

@end
