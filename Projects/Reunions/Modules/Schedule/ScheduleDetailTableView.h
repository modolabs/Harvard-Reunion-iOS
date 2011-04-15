#import "EventDetailTableView.h"
#import "KGOFoursquareEngine.h"

@interface ScheduleDetailTableView : EventDetailTableView <KGOFoursquareCheckinDelegate> {
    
    UILabel *_checkinHeader;
    NSString *_foursquareVenue;
    
    NSInteger _checkinStatus;
}

- (void)foursquareButtonPressed:(id)sender;
- (void)checkinFoursquarePlace;
- (void)setupFoursquareButton;

@end
