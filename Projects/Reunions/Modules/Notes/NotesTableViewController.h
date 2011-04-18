#import <UIKit/UIKit.h>
#import "KGOTableViewController.h"
#import "NewNoteViewController.h"
#import "Note.h"
#import "NotesTextView.h"


@class NewNoteViewController;

@interface NotesTableViewController : KGOTableViewController <NotesTextViewDelegate>{

    NSIndexPath * selectedRowIndexPath;
    NewNoteViewController * tempVC;
    
    NSArray * notesArray;
    
    Note * selectedNote;
}



-(UIButton *) customButtonWithText: (NSString *) title xOffset: (CGFloat) x yOffset: (CGFloat) y;

- (void) reloadNotes;

// called from the modal view (new note), upon delete
-(void) deleteNoteWithoutSaving;

@end
