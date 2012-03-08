
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import "EventDetailTableView.h"
#import "KGOFoursquareEngine.h"
#import <MapKit/MapKit.h>
#import <EventKitUI/EventKitUI.h>

@interface ScheduleDetailTableView : EventDetailTableView <KGOFoursquareCheckinDelegate,
MKMapViewDelegate, EKEventEditViewDelegate> {
    
    UILabel *_checkinHeader;

    NSString *_foursquareVenue;
    NSArray *_checkedInUsers;
    NSInteger _checkedInUserCount;
    
    NSInteger _checkinStatus;
    
}

- (void)foursquareButtonPressed:(id)sender;
- (void)presentFoursquareCheckinController;

// associated map view in expanded ipad cell.
@property(nonatomic, retain) MKMapView *mapView;

@end
