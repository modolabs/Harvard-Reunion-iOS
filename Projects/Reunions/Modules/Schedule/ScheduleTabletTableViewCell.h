#import <UIKit/UIKit.h>
#import "NewNoteViewController.h"

typedef enum {
    ScheduleCellTypeOther,
    ScheduleCellLastInTable,
    ScheduleCellSelected
} ScheduleCellType;

@class ScheduleEventWrapper;

@interface ScheduleTabletTableViewCell : UITableViewCell <UIAlertViewDelegate, NotesModalViewDelegate> {
    
    UIImageView *_fakeTopOfNextCell;
    
    UIButton *_bookmarkView;
    UIButton *_notesButton;
    
    ScheduleCellType _scheduleCellType;
    NewNoteViewController *_noteViewController;

}

@property (nonatomic, retain) ScheduleEventWrapper *event;
@property ScheduleCellType scheduleCellType;
@property (nonatomic, readonly) UIButton *bookmarkView;
@property (nonatomic) BOOL isFirstInSection;
@property (nonatomic, assign) UIViewController *parentViewController;

- (void)addBookmark:(id)sender;
- (void)attemptToAddBookmark:(id)sender;
- (void)removeBookmark:(id)sender;
- (void)refuseToRemoveBookmark:(id)sender;

- (void)noteButtonPressed:(id)sender;

@end


@interface ScheduleTabletSectionHeaderCell : UITableViewCell {
    
}

@property (nonatomic) BOOL isFirst;

@end


