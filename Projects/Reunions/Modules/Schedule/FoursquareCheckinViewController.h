#import "KGOTableViewController.h"
#import "KGOFoursquareEngine.h"

@class ScheduleDetailTableView;

@interface FoursquareCheckinViewController : KGOTableViewController <KGOFoursquareCheckinDelegate> {
    
    NSArray *_checkinData;
    NSArray *_filteredCheckinData;
    UITextField *_textField;
    UIButton *_button;
    
}

@property(nonatomic, retain) NSString *checkinMessage;
@property(nonatomic, retain) NSArray *checkinData;
@property(nonatomic, retain) NSString *eventTitle;
@property(nonatomic) BOOL isCheckedIn;
@property(nonatomic, retain) NSString *venue;
@property(nonatomic) NSInteger checkedInUserCount;
@property(nonatomic, retain) ScheduleDetailTableView *parentTableView;

 - (void)showCheckinDialog:(id)sender;

@end
