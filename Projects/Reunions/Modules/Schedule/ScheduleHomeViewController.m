#import "ScheduleHomeViewController.h"
#import "ScheduleDataManager.h"

@implementation ScheduleHomeViewController

- (void)loadView
{
    [super loadView];
    [_datePager removeFromSuperview];
    _datePager = nil;
    
    if (!self.dataManager) {
        self.dataManager = [[[ScheduleDataManager alloc] init] autorelease];
        self.dataManager.delegate = self;
        self.dataManager.moduleTag = self.moduleTag;
    }
}

@end
