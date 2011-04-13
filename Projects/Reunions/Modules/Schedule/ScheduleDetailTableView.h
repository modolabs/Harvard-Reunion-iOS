#import "EventDetailTableView.h"

@interface ScheduleDetailTableView : EventDetailTableView {
    
    UIButton *_foursquareButton;
    UILabel *_checkinLabel;
    
}

- (void)foursquareButtonPressed:(id)sender;

@end
