#import "EventDetailTableView.h"
#import "KGOFoursquareEngine.h"
#import <MapKit/MapKit.h>

@interface ScheduleDetailTableView : EventDetailTableView <KGOFoursquareCheckinDelegate, MKMapViewDelegate> {
    
    UILabel *_checkinHeader;

    NSString *_foursquareVenue;
    NSArray *_checkedInUsers;
    NSInteger _checkedInUserCount;
    
    NSInteger _checkinStatus;
    
    
}

- (void)foursquareButtonPressed:(id)sender;
//- (void)checkinFoursquarePlace;
//- (void)setupFoursquareButton;

// associated map view in expanded ipad cell.
@property(nonatomic, retain) MKMapView *mapView;

@end
