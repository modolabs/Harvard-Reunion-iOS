
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import <UIKit/UIKit.h>
#import "ScheduleHomeViewController.h"

@class ScheduleDetailTableView;

@interface ScheduleHomeViewController_iPad : ScheduleHomeViewController {
    
    NSIndexPath *_selectedIndexPath;
    NSMutableArray *_cellData;
    
    NSInteger _selectedRow;
    
    MKMapView *_mapViewForSelectedCell;
    MKMapView *_mapViewForLastCell;
    
    UIView *_mapContainerViewForSelectedCell;
    UIView *_mapContainerViewForLastCell;
    
    ScheduleDetailTableView *_tableViewForSelectedCell;
    ScheduleDetailTableView *_tableViewForLastCell;

}

- (void)mapViewTapped:(id)sender;

@property(nonatomic, retain) ScheduleEventWrapper *preselectedEvent;

@end
