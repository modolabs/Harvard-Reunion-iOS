
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import <UIKit/UIKit.h>
#import "KGORequest.h"

extern NSString * const AllReunionAttendeesPrefKey;

@interface AttendeesTableViewController : UIViewController <UITableViewDelegate,
UITableViewDataSource, KGORequestDelegate> {
    
    NSArray *_sectionTitles;
    NSMutableDictionary *_sections;
    UITableView *_tableView;
    NSArray *_attendees;
}

@property(nonatomic, retain) UITableView *tableView;
@property(nonatomic, retain) NSString *eventTitle;
@property(nonatomic) BOOL isPopup;
@property(nonatomic, retain) KGORequest *request;
@property(nonatomic, retain) NSArray *attendees;

@end
