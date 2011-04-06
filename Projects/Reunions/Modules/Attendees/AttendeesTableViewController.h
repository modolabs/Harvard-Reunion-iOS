#import <UIKit/UIKit.h>
#import "KGORequest.h"

extern NSString * const AllReunionAttendeesPrefKey;

@interface AttendeesTableViewController : UITableViewController <KGORequestDelegate> {
    
}

@property(nonatomic, retain) NSString *eventTitle;
@property(nonatomic, retain) KGORequest *request;
@property(nonatomic, retain) NSArray *attendees;

@end
