#import "AttendeesModule.h"
#import "AttendeesTableViewController.h"

@implementation AttendeesModule

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        
        AttendeesTableViewController *attendeesVC = [[[AttendeesTableViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
        vc = attendeesVC;
    }
    return vc;
}

@end
