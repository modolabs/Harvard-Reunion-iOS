#import <UIKit/UIKit.h>
#import "KGOTableViewController.h"
#import "Note.h"
#import "NotesTextView.h"
#import "NewNoteViewController.h"
#import <MessageUI/MFMailComposeViewController.h>
#import <UIKit/UIPrintInteractionController.h>

//@class NewNoteViewController;

@interface NotesTableViewController : KGOTableViewController <NotesTextViewDelegate, NotesModalViewDelegate, MFMailComposeViewControllerDelegate, UIPrintInteractionControllerDelegate>{

    NSIndexPath * selectedRowIndexPath;
    NewNoteViewController * tempVC;
    
    NSArray * notesArray;
    
    Note * selectedNote;
    
    BOOL firstView;
    
    UIButton *printAllButton;
}



-(UIButton *) customButtonWithText: (NSString *) title xOffset: (CGFloat) x yOffset: (CGFloat) y;

- (void) reloadNotes;
- (void) saveNotesState;
- (void) printContent: (NSString *) textToPrint jobTitle:(NSString *) jobTitle;

// called from the modal view (new note), upon delete
-(void) deleteNoteWithoutSaving;

@end
