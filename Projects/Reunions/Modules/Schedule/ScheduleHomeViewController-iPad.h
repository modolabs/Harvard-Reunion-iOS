#import <UIKit/UIKit.h>
#import "ScheduleHomeViewController.h"
#import "NewNoteViewController.h"

@class ScheduleDetailTableView;

@interface ScheduleHomeViewController_iPad : ScheduleHomeViewController <NotesModalViewDelegate>  {
    
    NSIndexPath *_selectedIndexPath;
    NSMutableArray *_cellData;
    
    NSInteger _selectedRow;
    NewNoteViewController *tempVC;
    
    MKMapView *_mapViewForSelectedCell;
    MKMapView *_mapViewForLastCell;
    
    ScheduleDetailTableView *_tableViewForSelectedCell;
    ScheduleDetailTableView *_tableViewForLastCell;

}

@end
