
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import <UIKit/UIKit.h>
#import "NewNoteViewController.h"

#define MAP_VIEW_TAG 556
#define DETAILS_VIEW_TAG 557

@class ScheduleEventWrapper;

@interface ScheduleTabletTableViewCell : UITableViewCell <UIAlertViewDelegate, NotesModalViewDelegate> {
    
    UIImageView *_fakeTopOfNextCell;
    
    UIButton *_bookmarkView;
    UIButton *_notesButton;
    
    BOOL _isLast;
    BOOL _isSelected;
    
    NewNoteViewController *_noteViewController;

}

@property (nonatomic, retain) ScheduleEventWrapper *event;
@property BOOL isLast;
@property BOOL isSelected;
@property (nonatomic, readonly) UIButton *bookmarkView;
@property (nonatomic, readonly) UIButton *notesButton;
@property (nonatomic) BOOL isFirstInSection;
@property (nonatomic) BOOL isAfterSelected;
@property (nonatomic, assign) UIViewController *parentViewController;

- (void)addBookmark;
- (void)attemptToAddBookmark:(id)sender;
- (void)attemptToRemoveBookmark:(id)sender;

- (void)noteButtonPressed:(id)sender;

@end


@interface ScheduleTabletSectionHeaderCell : UITableViewCell {
    
}

@property (nonatomic) BOOL isFirst;
@property (nonatomic) BOOL isAfterSelected;

@end


