#import "CalendarHomeViewController.h"

@interface ScheduleHomeViewController : CalendarHomeViewController {

    // tablet properties
    BOOL _isTablet;
    NSIndexPath *_selectedIndexPath;
    
    NSMutableDictionary *_myEvents;
}

@end
