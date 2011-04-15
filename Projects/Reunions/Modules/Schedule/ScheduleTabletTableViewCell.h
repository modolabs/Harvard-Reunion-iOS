#import <UIKit/UIKit.h>

typedef enum {
    ScheduleCellTypeOther,
    ScheduleCellAboveSelectedRow,
    ScheduleCellLastInTable,
    ScheduleCellLastInSection,
    ScheduleCellSelected
} ScheduleCellType;

@interface ScheduleTabletTableViewCell : UITableViewCell {
    
    UIView *_fakeCardBorder;
    UIImageView *_fakeTopOfNextCell;
    
    ScheduleCellType _scheduleCellType;
}

@property (nonatomic, assign) UITableView *tableView;
@property ScheduleCellType scheduleCellType;
@property BOOL isFirstInSection;

@end
