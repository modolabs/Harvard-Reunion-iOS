#import "ScheduleHomeViewController-iPad.h"
#import "ScheduleTabletTableViewCell.h"
#import "ScheduleDetailTableView.h"
#import "ScheduleEventWrapper.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import <QuartzCore/QuartzCore.h>
#import "MapKit+KGOAdditions.h"
#import "UIKit+KGOAdditions.h"
#import "ReunionMapModule.h"
#import "KGOSidebarFrameViewController.h"
#import "MapHomeViewController.h"

#define COLLAPSED_CELL_HEIGHT 58
#define EXPANDED_CELL_HEIGHT 500
#define LAST_CELL_HEIGHT EXPANDED_CELL_HEIGHT + 30

#define MAP_WIDTH_PORTRAIT 285
#define MAP_WIDTH_LANDSCAPE 332

#define SCHEDULE_DETAIL_WIDTH_PORTRAIT 302
#define SCHEDULE_DETAIL_WIDTH_LANDSCAPE 350

@interface ScheduleHomeViewController_iPad (Private)

- (UIView *)mapContainerViewForCell:(ScheduleTabletTableViewCell *)cell;
- (ScheduleDetailTableView *)tableViewForCell:(ScheduleTabletTableViewCell *)cell;

@end

@implementation ScheduleHomeViewController_iPad

@synthesize preselectedEvent;

/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/
- (void)dealloc
{
    [_mapViewForLastCell release];
    [_mapViewForSelectedCell release];
    [_mapContainerViewForLastCell release];
    [_mapContainerViewForSelectedCell release];
    [_tableViewForSelectedCell release];
    [_tableViewForLastCell release];
    self.preselectedEvent = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void)loadTableViewWithStyle:(UITableViewStyle)style
{
    CGRect frame = self.view.frame;
    frame.origin.y = _tabstrip.frame.size.height;
    frame.size.height -= _tabstrip.frame.size.height;
    
    // ignore style parameter
    self.tableView = [[[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain] autorelease];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.backgroundView = nil;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;

    self.tableView.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.tableView.layer.shadowOffset = CGSizeMake(1, 0);
    self.tableView.layer.shadowRadius = 1;
    self.tableView.layer.shadowOpacity = 0.75;
    
    self.tableView.tableHeaderView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 10)] autorelease];
    self.tableView.tableHeaderView.backgroundColor = [UIColor clearColor];
    
    self.tableView.autoresizesSubviews = YES;
    
    [self addTableView:self.tableView withDataSource:self];
}


- (void)eventsDidChange:(NSArray *)events calendar:(KGOCalendar *)calendar
{
    if (calendar && _currentCalendar != calendar) {
        return;
    }

    [self clearEvents];
    
    [_cellData release];
    _cellData = [[NSMutableArray alloc] init];
    
    _selectedRow = NSNotFound;

    if (events.count) {
        // TODO: make sure this set of events is what we last requested
        NSMutableArray *sectionTitles = [NSMutableArray array];
        NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:YES]];
        NSArray *sortedEvents = [events sortedArrayUsingDescriptors:sortDescriptors];
        KGOEventWrapper *firstEvent = [sortedEvents objectAtIndex:0];
        KGOEventWrapper *lastEvent = [sortedEvents lastObject];
        NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
        NSTimeInterval interval = [lastEvent.startDate timeIntervalSinceDate:firstEvent.startDate];
        if (isOverOneMonth(interval)) {
            [formatter setDateFormat:@"MMMM"];
            
        } else if (isOverOneDay(interval)) {
            [formatter setDateFormat:@"EEE MMMM d"];
            
        } else if (isOverOneHour(interval)) {
            [formatter setDateFormat:@"h a"];
            
        } else {
            [formatter setDateStyle:NSDateFormatterNoStyle];
            [formatter setTimeStyle:NSDateFormatterNoStyle];
        }

        for (KGOEventWrapper *event in sortedEvents) {
            NSString *title = [formatter stringFromDate:event.startDate];
            if (![sectionTitles containsObject:title]) {
                [sectionTitles addObject:title];
                [_cellData addObject:title];
            }
            [_cellData addObject:event];
            
            if (self.preselectedEvent && [event.identifier isEqualToString:self.preselectedEvent.identifier]) {
                _selectedRow = _cellData.count - 1;
            }
            DLog(@"added new event %@ %@ %@ %d %d",
                 event.title, event.identifier, self.preselectedEvent.identifier, _cellData.count, _selectedRow);
        }
    }
    
    [_loadingView stopAnimating];
    self.tableView.hidden = NO;
    [self reloadDataForTableView:self.tableView];
}

#pragma mark table view methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_cellData count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.preselectedEvent = nil;
    
    if (indexPath.row == _selectedRow) {
        return;
    }
    
    NSIndexPath *oldIndexPath = nil;
    
    NSInteger oldSelectedRow = _selectedRow;
    _selectedRow = indexPath.row;
    
    if (oldSelectedRow != NSNotFound) {
        oldIndexPath = [NSIndexPath indexPathForRow:oldSelectedRow inSection:0];
    }
    
    NSIndexPath *scrollToIndexPath = nil;

    if (_selectedRow == 0) {
        scrollToIndexPath = indexPath;
    } else if (_selectedRow == 1) {
        scrollToIndexPath = [NSIndexPath indexPathForRow:_selectedRow - 1 inSection:0];
    } else {
        scrollToIndexPath = [NSIndexPath indexPathForRow:_selectedRow - 2 inSection:0];
    }
    
    /*
    UITableViewRowAnimation animation = UITableViewRowAnimationNone;
    
    if (_selectedRow == 0) {
        if (oldIndexPath) {
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:oldIndexPath]
                             withRowAnimation:UITableViewRowAnimationMiddle];
        }
        
    } else {
        if (oldIndexPath) {
            if (oldSelectedRow < _selectedRow) { // the previously expanded row is above us
                [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:oldIndexPath]
                                 withRowAnimation:UITableViewRowAnimationNone];
            } else {
                //animation = UITableViewRowAnimationMiddle;
                [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:oldIndexPath]
                                 withRowAnimation:UITableViewRowAnimationNone];
            }
        }
    }
    */
    

    if (oldIndexPath) {
        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:oldIndexPath, indexPath, nil]
                         withRowAnimation:UITableViewRowAnimationNone];
    } else {
        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                         withRowAnimation:UITableViewRowAnimationNone];
    }
    
    // Update row after previously selected row to get little curvy bits updated
    if (oldSelectedRow != NSNotFound && oldSelectedRow < _cellData.count - 1) {
        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:oldSelectedRow+1 inSection:0]]
                         withRowAnimation:UITableViewRowAnimationNone];
    }

    // Update row after selected row to get little curvy bits updated
    if (_selectedRow < _cellData.count - 1) {
        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:_selectedRow+1 inSection:0]]
                         withRowAnimation:UITableViewRowAnimationNone];
    }

    [tableView scrollToRowAtIndexPath:scrollToIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

#define SELECTED_MAP_TAG 2
#define LAST_MAP_TAG 3

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id currentCellData = [_cellData objectAtIndex:indexPath.row];
    if ([currentCellData isKindOfClass:[NSString class]]) {
        BOOL isFirst = NO;
        BOOL isAfterSelected = NO;
        if (indexPath.row == 0) {
            isFirst = YES;
        } else if ((indexPath.row - 1) == _selectedRow) {
            isAfterSelected = YES;
        }

        NSString *sectionHeaderCellID = [NSString stringWithFormat:@"Header_%@%@", isFirst ? @"1" : @"0", isAfterSelected ? @"1" : @"0"];
        ScheduleTabletSectionHeaderCell *cell = (ScheduleTabletSectionHeaderCell *)[tableView dequeueReusableCellWithIdentifier:sectionHeaderCellID];
        
        if (!cell) {
            cell = [[[ScheduleTabletSectionHeaderCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                           reuseIdentifier:sectionHeaderCellID] autorelease];
        }
        
        cell.isFirst = isFirst;
        cell.isAfterSelected = isAfterSelected;
        cell.textLabel.text = (NSString *)currentCellData;
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
        
        return cell;
    }
    
    BOOL isLast = NO;
    BOOL isSelected = NO;
    BOOL isFirstInSection = NO;
    BOOL isAfterSelected = NO;

    if (indexPath.row == _selectedRow) {
        isSelected = YES;
    } 
    if (indexPath.row == _cellData.count - 1) {
        isLast = YES;
    }
    if (indexPath.row > 0) {
        id previousCellData = [_cellData objectAtIndex:indexPath.row - 1];
        isFirstInSection = [previousCellData isKindOfClass:[NSString class]];
        if ((indexPath.row - 1) == _selectedRow) {
            isAfterSelected = YES;
        }
    }
    
    NSString *cellIdentifier = [NSString stringWithFormat:@"Cell_%@%@%@", isLast ? @"1" : @"0", isSelected ? @"1" : @"0", isFirstInSection ? @"1" : @"0", isAfterSelected ? @"1" : @"0"];
    ScheduleTabletTableViewCell *cell = (ScheduleTabletTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[[ScheduleTabletTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                                   reuseIdentifier:cellIdentifier] autorelease];
    }
    
    cell.isLast = isLast;
    cell.isSelected = isSelected;
    cell.isFirstInSection = isFirstInSection;
    cell.isAfterSelected = isAfterSelected;
    cell.parentViewController = self;
    
    ScheduleEventWrapper *event = [_cellData objectAtIndex:indexPath.row];
    
    cell.event = event;
    
    cell.textLabel.text = event.title;
    cell.detailTextLabel.text = [self.dataManager shortDateTimeStringFromDate:event.startDate];
    
    UIImage *image = nil;
    if ([event isRegistered] || [event isBookmarked]) {
        cell.bookmarkView.hidden = NO;
        image = [UIImage imageWithPathName:@"common/bookmark-ribbon-on"];
        
    } else if (cell.isSelected) {
        cell.bookmarkView.hidden = NO;
        image = [UIImage imageWithPathName:@"common/bookmark-ribbon-off"];
        
    } else {
        cell.bookmarkView.hidden = YES;
    }
    
    if (image) {
        [cell.bookmarkView setImage:image forState:UIControlStateNormal];
    }
    
    cell.notesButton.hidden = (!cell.isSelected && ![event note]);
    
    if (cell.isLast || cell.isSelected) {
        ScheduleDetailTableView *tableView = [self tableViewForCell:cell];
        tableView.event = event;
        [cell.contentView addSubview:tableView];
        
        UIView *mapContainerView = [self mapContainerViewForCell:cell];
        MKMapView *mapView = (MKMapView *)[mapContainerView viewWithTag:(cell.isSelected) ? SELECTED_MAP_TAG : LAST_MAP_TAG];
        
        if (event.coordinate.latitude) {
            // we only need to check one assuming there will not
            // be any events on the equator
            [mapView addAnnotation:event];
            mapView.region = MKCoordinateRegionMake(event.coordinate, MKCoordinateSpanMake(0.01, 0.01));
        } else {
            [mapView centerAndZoomToDefaultRegion];
        }
        
        [cell.contentView addSubview:mapContainerView];
        
        tableView.mapView = mapView;
        mapView.delegate = tableView;
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (ScheduleDetailTableView *)tableViewForCell:(ScheduleTabletTableViewCell *)cell
{
    ScheduleDetailTableView *tableView = nil;
    BOOL needsInitialize = NO;
    if (cell.isSelected) {
        if (!_tableViewForSelectedCell) {
            CGFloat width = SCHEDULE_DETAIL_WIDTH_PORTRAIT;
            UIViewController *homescreen = [KGO_SHARED_APP_DELEGATE() homescreen];
            if (UIInterfaceOrientationIsLandscape(homescreen.interfaceOrientation)) {
                width = SCHEDULE_DETAIL_WIDTH_LANDSCAPE;
            }
            _tableViewForSelectedCell = [[ScheduleDetailTableView alloc] initWithFrame:CGRectMake(0, 50, width, EXPANDED_CELL_HEIGHT - 50)
                                                                                 style:UITableViewStyleGrouped];
            needsInitialize = YES;
        }
        tableView = _tableViewForSelectedCell;

    } else if (cell.isLast) {
        if (!_tableViewForLastCell) {
            CGFloat width = SCHEDULE_DETAIL_WIDTH_PORTRAIT;
            UIViewController *homescreen = [KGO_SHARED_APP_DELEGATE() homescreen];
            if (UIInterfaceOrientationIsLandscape(homescreen.interfaceOrientation)) {
                width = SCHEDULE_DETAIL_WIDTH_LANDSCAPE;
            }
            _tableViewForLastCell = [[ScheduleDetailTableView alloc] initWithFrame:CGRectMake(0, 50, width, LAST_CELL_HEIGHT - 50)
                                                                             style:UITableViewStyleGrouped];
            needsInitialize = YES;
        }
        tableView = _tableViewForLastCell;
    }
    
    if (needsInitialize) {
        tableView.backgroundColor = [UIColor clearColor];
        tableView.backgroundView = nil;
        tableView.tag = DETAILS_VIEW_TAG;
        tableView.dataManager = self.dataManager;
        tableView.viewController = [KGO_SHARED_APP_DELEGATE() visibleViewController];
    }
    
    [tableView removeFromSuperview];
    
    return tableView;
}


- (UIView *)mapContainerViewForCell:(ScheduleTabletTableViewCell *)cell
{
    MKMapView *mapView = nil;
    UIView *containerView = nil;
    
    BOOL isNew = NO; // yes if the view does not exist and has not been laid out yet
    
    if (cell.isSelected) {
        if (!_mapViewForSelectedCell) {
            isNew = YES;
            CGFloat width = MAP_WIDTH_PORTRAIT;
            CGFloat x = SCHEDULE_DETAIL_WIDTH_PORTRAIT;
            UIViewController *homescreen = [KGO_SHARED_APP_DELEGATE() homescreen];
            if (UIInterfaceOrientationIsLandscape(homescreen.interfaceOrientation)) {
                width = MAP_WIDTH_LANDSCAPE;
                x = SCHEDULE_DETAIL_WIDTH_LANDSCAPE;
            }
            _mapContainerViewForSelectedCell = [[UIView alloc] initWithFrame:CGRectMake(x, 60, width, EXPANDED_CELL_HEIGHT - 70)];
            _mapViewForSelectedCell = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, width, EXPANDED_CELL_HEIGHT - 70)];
            _mapViewForSelectedCell.tag = SELECTED_MAP_TAG;
        }
        containerView = _mapContainerViewForSelectedCell;
        mapView = _mapViewForSelectedCell;
        
    } else if (cell.isLast) {
        if (!_mapViewForLastCell) {
            isNew = YES;
            CGFloat width = MAP_WIDTH_PORTRAIT;
            CGFloat x = SCHEDULE_DETAIL_WIDTH_PORTRAIT;
            UIViewController *homescreen = [KGO_SHARED_APP_DELEGATE() homescreen];
            if (UIInterfaceOrientationIsLandscape(homescreen.interfaceOrientation)) {
                width = MAP_WIDTH_LANDSCAPE;
                x = SCHEDULE_DETAIL_WIDTH_LANDSCAPE;
            }
            _mapContainerViewForLastCell = [[UIView alloc] initWithFrame:CGRectMake(x, 60, width, LAST_CELL_HEIGHT - 70)];
            _mapViewForLastCell = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, width, LAST_CELL_HEIGHT - 70)];
            _mapViewForLastCell.tag = LAST_MAP_TAG;
        }
        containerView = _mapContainerViewForLastCell;
        mapView = _mapViewForLastCell;
    }
    
    if (isNew) {
        mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        mapView.userInteractionEnabled = NO;
        
        containerView.tag = MAP_VIEW_TAG;
        containerView.layer.cornerRadius = 5.0;
        containerView.layer.borderColor = [[UIColor grayColor] CGColor];
        containerView.layer.borderWidth = 1.0;
        containerView.clipsToBounds = YES;
        containerView.autoresizesSubviews = YES;
        [containerView addSubview:mapView];
        
        UIControl *control = [[[UIControl alloc] initWithFrame:containerView.bounds] autorelease];
        control.backgroundColor = [UIColor clearColor];
        [control addTarget:self action:@selector(mapViewTapped:) forControlEvents:UIControlEventTouchUpInside];
        control.tag = mapView.tag;
        [containerView addSubview:control];
        
    } else {
        [mapView removeAnnotations:[mapView annotations]];
    }
    
    return containerView;
}

- (void)mapViewTapped:(id)sender
{
    if ([sender isKindOfClass:[UIControl class]] || [sender isKindOfClass:[MKMapView class]]) {
        MKMapView *mapView = nil;
        
        if ([sender tag] == SELECTED_MAP_TAG) {
            mapView = _mapViewForSelectedCell;
        } else {
            mapView = _mapViewForLastCell;
        }
        
        if (!mapView.annotations.count) { // unknown location -- nothing to select on map
            return;
        }
        
        CGRect outsideFrame = self.view.bounds;
        outsideFrame.origin = CGPointMake(18, 60);
        outsideFrame.size.width -= 32;
        outsideFrame.size.height -= 80;
        
        MKCoordinateRegion outsideRegion = [mapView convertRect:outsideFrame toRegionFromView:self.view];
        NSArray *startRegion = [NSArray arrayWithObjects:
                                [NSNumber numberWithFloat:mapView.region.center.latitude],
                                [NSNumber numberWithFloat:mapView.region.center.longitude],
                                [NSNumber numberWithFloat:mapView.region.span.latitudeDelta],
                                [NSNumber numberWithFloat:mapView.region.span.longitudeDelta],
                                nil];

        NSArray *endRegion = [NSArray arrayWithObjects:
                              [NSNumber numberWithFloat:outsideRegion.center.latitude],
                              [NSNumber numberWithFloat:outsideRegion.center.longitude],
                              [NSNumber numberWithFloat:outsideRegion.span.latitudeDelta],
                              [NSNumber numberWithFloat:outsideRegion.span.longitudeDelta],
                              nil];
        
        CGRect mapFrame = [mapView convertRect:mapView.frame toView:self.view];
        mapFrame.origin.x = 320;
        mapFrame.origin.y -= 56;
        
        NSArray *startFrame = [NSArray arrayWithObjects:
                               [NSNumber numberWithFloat:mapFrame.origin.x],
                               [NSNumber numberWithFloat:mapFrame.origin.y],
                               [NSNumber numberWithFloat:mapFrame.size.width],
                               [NSNumber numberWithFloat:mapFrame.size.height],
                               nil];
        
        KGOSidebarFrameViewController *homescreen = (KGOSidebarFrameViewController *)[KGO_SHARED_APP_DELEGATE() homescreen];
        homescreen.animationDuration = 1;
        
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                mapView.annotations, @"annotations",
                                startFrame, @"startFrame",
                                startRegion, @"startRegion",
                                endRegion, @"endRegion",
                                nil];
        [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameHome forModuleTag:MapTag params:params];
        homescreen.animationDuration = 0.2;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id currentCellData = [_cellData objectAtIndex:indexPath.row];
    if ([currentCellData isKindOfClass:[NSString class]]) {
        return 24;
    }
    
    if (indexPath.row == _cellData.count - 1) {
        return LAST_CELL_HEIGHT;
    }
    
    if (indexPath.row == _selectedRow) {
        return EXPANDED_CELL_HEIGHT;
    }
    
    return COLLAPSED_CELL_HEIGHT;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    UIViewController *homescreen = [KGO_SHARED_APP_DELEGATE() homescreen];
    
    // set table view and its container
    CGRect tableViewSelectedFrame = _tableViewForSelectedCell.frame;
    CGRect tableViewLastFrame = _tableViewForLastCell.frame;
    
    if (UIInterfaceOrientationIsPortrait(homescreen.interfaceOrientation)) {
        tableViewSelectedFrame.size.width = SCHEDULE_DETAIL_WIDTH_PORTRAIT;
        tableViewLastFrame.size.width = SCHEDULE_DETAIL_WIDTH_PORTRAIT;
        
    } else {
        tableViewSelectedFrame.size.width = SCHEDULE_DETAIL_WIDTH_LANDSCAPE;
        tableViewLastFrame.size.width = SCHEDULE_DETAIL_WIDTH_LANDSCAPE;
    }

    // Set map view and its container
    CGRect mapContainerViewSelectedFrame = _mapContainerViewForSelectedCell.frame;
    CGRect mapContainerViewLastFrame = _mapContainerViewForLastCell.frame;
    
    if (UIInterfaceOrientationIsPortrait(homescreen.interfaceOrientation)) {
        mapContainerViewSelectedFrame.size.width = MAP_WIDTH_PORTRAIT;
        mapContainerViewSelectedFrame.origin.x = SCHEDULE_DETAIL_WIDTH_PORTRAIT;

        mapContainerViewLastFrame.size.width = MAP_WIDTH_PORTRAIT;
        mapContainerViewLastFrame.origin.x = SCHEDULE_DETAIL_WIDTH_PORTRAIT;
        
    } else {
        mapContainerViewSelectedFrame.size.width = MAP_WIDTH_LANDSCAPE;
        mapContainerViewSelectedFrame.origin.x = SCHEDULE_DETAIL_WIDTH_LANDSCAPE;

        mapContainerViewLastFrame.size.width = MAP_WIDTH_LANDSCAPE;
        mapContainerViewLastFrame.origin.x = SCHEDULE_DETAIL_WIDTH_LANDSCAPE;
    }
    _tableViewForSelectedCell.frame = tableViewSelectedFrame;
    _tableViewForLastCell.frame = tableViewLastFrame;
    [_tableViewForSelectedCell reloadData];
    [_tableViewForLastCell reloadData];
    
    _mapContainerViewForSelectedCell.frame = mapContainerViewSelectedFrame;
    _mapContainerViewForLastCell.frame = mapContainerViewLastFrame;
}

@end
