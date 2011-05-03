#import "MapModule.h"

extern NSString * const EventMapCategoryName;

@class ScheduleDataManager;

@interface ReunionMapModule : MapModule {
    ScheduleDataManager *scheduleManager;

}

@end
