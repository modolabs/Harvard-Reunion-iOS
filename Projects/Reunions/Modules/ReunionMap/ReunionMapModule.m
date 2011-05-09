#import "ReunionMapModule.h"
#import "KGOPlacemark.h"
#import "ReunionMapDetailViewController.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "ReunionMapHomeViewController.h"
#import "KGOSidebarFrameViewController.h"
#import "ScheduleDataManager.h"
#import "KGOMapCategory.h"
#import "ScheduleEventWrapper.h"

NSString * const EventMapCategoryName = @"event"; // this is what the mobile web gives us
NSString * const ScheduleTag = @"schedule";

@implementation ReunionMapModule

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    
    if ([pageName isEqualToString:LocalPathPageNameDetail]) {
        ReunionMapDetailViewController *detailVC = [[[ReunionMapDetailViewController alloc] init] autorelease];
        
        KGOPlacemark *detailItem = [params objectForKey:@"detailItem"];
        if (detailItem) {
            NSArray *annotations = [NSArray arrayWithObject:detailItem];
            NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:annotations, @"annotations", nil];
            
            UIViewController *topVC = [KGO_SHARED_APP_DELEGATE() visibleViewController];
            if (topVC.modalViewController) {
                [topVC dismissModalViewControllerAnimated:YES];
            }
            
            KGONavigationStyle navStyle = [KGO_SHARED_APP_DELEGATE() navigationStyle];
            if (navStyle == KGONavigationStyleTabletSidebar) {
                KGOSidebarFrameViewController *homescreen = (KGOSidebarFrameViewController *)[KGO_SHARED_APP_DELEGATE() homescreen];
                topVC = homescreen.visibleViewController;
                if (topVC.modalViewController) {
                    [topVC dismissModalViewControllerAnimated:YES];
                }
            }
            
            if ([topVC isKindOfClass:[MapHomeViewController class]]) {
                MapHomeViewController *mapVC = (MapHomeViewController *)topVC;
                [mapVC setAnnotations:annotations];
                if (mapVC.selectedPopover) {
                    [mapVC dismissPopoverAnimated:YES];
                    return nil;
                }
                
            } else {
                return [self modulePage:LocalPathPageNameHome params:params];
            }
        }
        
        KGOPlacemark *place = [params objectForKey:@"place"];
        if (place) {
            detailVC.annotation = place;
            //detailVC.placemark = place;
        }
        id<KGODetailPagerController> controller = [params objectForKey:@"pagerController"];
        if (controller) {
            KGODetailPager *pager = [[[KGODetailPager alloc] initWithPagerController:controller delegate:detailVC] autorelease];
            detailVC.pager = pager;
        }
        
        return detailVC;
        
    } else if([pageName isEqualToString:LocalPathPageNameHome]) {
        
        ReunionMapHomeViewController *mapVC = nil;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            mapVC = [[[ReunionMapHomeViewController alloc] initWithNibName:@"MapHomeViewController" bundle:nil] autorelease];
        } else {
            if ([[NSBundle mainBundle] pathForResource:@"MapHomeViewController-iPad" ofType:@"nib"] != nil) {
                mapVC = [[[ReunionMapHomeViewController alloc] initWithNibName:@"MapHomeViewController-iPad" bundle:nil] autorelease];
            } else {
                mapVC = [[[ReunionMapHomeViewController alloc] initWithNibName:@"MapHomeViewController" bundle:nil] autorelease];
            }
        }
        
        mapVC.mapModule = self;
        
        NSString *searchText = [params objectForKey:@"q"];
        if (searchText) {
            mapVC.searchTerms = searchText;
            mapVC.searchOnLoad = YES;
            mapVC.searchParams = params;
        }
        
        NSArray *annotations = [params objectForKey:@"annotations"];
        if (annotations) {
            NSLog(@"annotations: %@", annotations);
            mapVC.annotations = annotations;
        }
        
        NSArray *frameParts = [params objectForKey:@"startFrame"];
        if (frameParts) {
            CGRect frame = CGRectMake([[frameParts objectAtIndex:0] floatValue],
                                      [[frameParts objectAtIndex:1] floatValue],
                                      [[frameParts objectAtIndex:2] floatValue],
                                      [[frameParts objectAtIndex:3] floatValue]);
            mapVC.startFrame = frame;
        }
        
        NSArray *regionParts = [params objectForKey:@"startRegion"];
        if (regionParts) {
            CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([[regionParts objectAtIndex:0] floatValue],
                                                                           [[regionParts objectAtIndex:1] floatValue]);
            MKCoordinateSpan span = MKCoordinateSpanMake([[regionParts objectAtIndex:2] floatValue],
                                                         [[regionParts objectAtIndex:3] floatValue]);
            
            MKCoordinateRegion region = MKCoordinateRegionMake(coordinate, span);
            mapVC.startRegion = region;
        }
        
        regionParts = [params objectForKey:@"endRegion"];
        if (regionParts) {
            CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([[regionParts objectAtIndex:0] floatValue],
                                                                           [[regionParts objectAtIndex:1] floatValue]);
            MKCoordinateSpan span = MKCoordinateSpanMake([[regionParts objectAtIndex:2] floatValue],
                                                         [[regionParts objectAtIndex:3] floatValue]);
            
            MKCoordinateRegion region = MKCoordinateRegionMake(coordinate, span);
            mapVC.endRegion = region;
        }
        
        // schedule needs to be loaded in case user taps on
        // annotation that corresponds to an event
        if(!scheduleManager) {
            scheduleManager = [ScheduleDataManager new];
            scheduleManager.moduleTag = ScheduleTag;
        }
        if (![scheduleManager allEvents]) {
            [scheduleManager requestAllEvents];
        }

        return mapVC;
    }
    
    return [super modulePage:pageName params:params];
}

- (void)dealloc {
    [scheduleManager release];
    [super dealloc];
}

- (void)request:(KGORequest *)request didReceiveResult:(id)result {
    if (request == self.request) {
        self.request = nil;
        
        NSArray *resultArray = [result arrayForKey:@"results"];
        NSMutableArray *searchResults = [NSMutableArray arrayWithCapacity:[(NSArray *)resultArray count]];
        for (id aResult in resultArray) {
            KGOPlacemark *placemark = [KGOPlacemark placemarkWithDictionary:aResult];
            if (placemark) {
                if ([placemark.category.identifier isEqualToString:EventMapCategoryName]) {
                    ScheduleEventWrapper *event = [[[ScheduleEventWrapper alloc] initWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:placemark.identifier, @"id", nil]] autorelease];
                    event.coordinate = placemark.coordinate;
                    event.title = placemark.title;
                    [event saveToCoreData];
                    [searchResults addObject:event];
                } else {
                    [searchResults addObject:placemark];
                }
            }
        }
        DLog(@"%@", searchResults);
        [self.searchDelegate searcher:self didReceiveResults:searchResults];
    }
}


@end
