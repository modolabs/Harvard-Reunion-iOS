#import <UIKit/UIKit.h>
#import "KGORequest.h"

extern NSString * const AllReunionAttendeesPrefKey;

@interface AttendeesTableViewController : UIViewController <UITableViewDelegate,
UITableViewDataSource, KGORequestDelegate> {
    
    NSArray *_sectionTitles;
    NSMutableDictionary *_sections;
    UITableView *_tableView;
}

@property(nonatomic, retain) UITableView *tableView;
@property(nonatomic, retain) NSString *eventTitle;
@property(nonatomic, retain) KGORequest *request;
@property(nonatomic, retain) NSArray *attendees;

@end
