#import "NotesModule.h"
#import "NotesTableViewController.h"

@implementation NotesModule

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        
        NotesTableViewController *notesVC = [[[NotesTableViewController alloc] initWithStyle:UITableViewStylePlain] autorelease];
        vc = notesVC;
    }
    return vc;
}

@end
