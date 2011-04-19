#import "CalendarHomeViewController.h"
#import "NewNoteViewController.h"

@interface ScheduleHomeViewController : CalendarHomeViewController <NotesModalViewDelegate>{

    // tablet properties
    BOOL _isTablet;
    NSIndexPath *_selectedIndexPath;
    
    NSMutableDictionary *_myEvents;
    
    NewNoteViewController *tempVC;
}

@end
