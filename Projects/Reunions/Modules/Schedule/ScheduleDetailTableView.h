#import "EventDetailTableView.h"

@interface ScheduleDetailTableView : EventDetailTableView {
    
    UIButton *_foursquareButton;
    UIButton *_facebookButton;
    
}

- (void)foursquareButtonPressed:(id)sender;
- (void)facebookButtonPressed:(id)sender;

@end
