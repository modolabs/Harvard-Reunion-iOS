#import <UIKit/UIKit.h>
#import "KGOTableViewController.h"
#import "NewNoteViewController.h"


@class NewNoteViewController;

@interface NotesTableViewController : KGOTableViewController{

    NSIndexPath * selectedRowIndexPath;
    NewNoteViewController * tempVC;
}



-(UIButton *) customButtonWithText: (NSString *) title xOffset: (CGFloat) x yOffset: (CGFloat) y;

@end
