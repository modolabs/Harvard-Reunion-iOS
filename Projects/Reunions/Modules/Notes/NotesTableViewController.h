#import <UIKit/UIKit.h>
#import "KGOTableViewController.h"



@interface NotesTableViewController : KGOTableViewController{

    NSIndexPath * selectedRowIndexPath;
}



-(UIButton *) customButtonWithText: (NSString *) title xOffset: (CGFloat) x yOffset: (CGFloat) y;

@end
