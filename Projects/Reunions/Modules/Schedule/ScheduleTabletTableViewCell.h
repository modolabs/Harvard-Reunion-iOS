#import <UIKit/UIKit.h>

typedef enum {
    ScheduleCellTypeOther,
    ScheduleCellLastInTable,
    ScheduleCellSelected
} ScheduleCellType;

@class ScheduleEventWrapper;

@interface ScheduleTabletTableViewCell : UITableViewCell <UIAlertViewDelegate> {
    
    UIImageView *_fakeTopOfNextCell;
    
    UIButton *_bookmarkView;
    UIButton *_notesButton;
    
    ScheduleCellType _scheduleCellType;
}

@property (nonatomic, retain) ScheduleEventWrapper *event;
@property ScheduleCellType scheduleCellType;
@property (nonatomic, readonly) UIButton *bookmarkView;
@property (nonatomic) BOOL isFirstInSection;

- (void)addBookmark:(id)sender;
- (void)attemptToAddBookmark:(id)sender;
- (void)removeBookmark:(id)sender;
- (void)refuseToRemoveBookmark:(id)sender;

@end


@interface ScheduleTabletSectionHeaderCell : UITableViewCell {
    
}

@property (nonatomic) BOOL isFirst;

@end


