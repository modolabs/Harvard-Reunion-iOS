#import "EventDetailTableView.h"
#import "KGOFoursquareEngine.h"

@interface ScheduleDetailTableView : EventDetailTableView <KGOFoursquareCheckinDelegate> {
    
    UIButton *_foursquareButton;
    UILabel *_checkinLabel;
    
}

- (BOOL)shouldShowFoursquareButton;

- (void)foursquareButtonPressed:(id)sender;

- (void)checkinFoursquarePlace;

@end
