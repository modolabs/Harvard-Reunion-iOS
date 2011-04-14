#import "EventDetailTableView.h"
#import "KGOFoursquareEngine.h"

@interface ScheduleDetailTableView : EventDetailTableView <KGOFoursquareCheckinDelegate> {
    
    UIButton *_foursquareButton;
    UILabel *_checkinLabel;
    NSString *_foursquareVenue;
    
    NSInteger _checkinStatus;
}

- (void)foursquareButtonPressed:(id)sender;
- (void)checkinFoursquarePlace;
- (void)setupFoursquareButton;

@end
