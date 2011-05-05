#import <UIKit/UIKit.h>
#import "NotesTextView.h"

typedef enum {
    NotesCellTypeOther,
    NotesCellLastInTable,
    NotesCellSelected
} NotesCellType;

@interface NotesUnselectedTableViewCell : UITableViewCell {
    
    NotesCellType notesCellType;
    
    NotesTextView * detailsView;

}

@property (nonatomic, assign) UITableView *tableView;
@property NotesCellType notesCellType;
@property (nonatomic, retain)  NotesTextView *detailsView;


@end
