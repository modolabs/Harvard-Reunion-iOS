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
    UIButton *_bookmarkView;
    
    ScheduleCellType _scheduleCellType;
}

@property (nonatomic, assign) UITableView *tableView;
@property ScheduleCellType scheduleCellType;
@property BOOL isFirstInSection;
@property (nonatomic, readonly) UIButton *bookmarkView;

@end
