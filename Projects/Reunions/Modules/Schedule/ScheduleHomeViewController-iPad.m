#import "ScheduleHomeViewController-iPad.h"
#import "ScheduleTabletTableViewCell.h"
#import "ScheduleDetailTableView.h"
#import "ScheduleEventWrapper.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import <QuartzCore/QuartzCore.h>
#import "MapKit+KGOAdditions.h"
#import "UIKit+KGOAdditions.h"
#import "Note.h"

@interface ScheduleHomeViewController_iPad (Private)

- (MKMapView *)mapViewForCellType:(ScheduleCellType)cellType;
- (ScheduleDetailTableView *)tableViewForCellType:(ScheduleCellType)cellType;

@end

@implementation ScheduleHomeViewController_iPad
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
    [_tableViewForSelectedCell release];
    [_tableViewForLastCell release];
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
    
    // ignore style parameter
    self.tableView = [[[UITableView alloc] initWithFrame:frame style:UITableViewStyleGrouped] autorelease];
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
    
    [self addTableView:self.tableView withDataSource:self];
}


- (void)eventsDidChange:(NSArray *)events calendar:(KGOCalendar *)calendar
{
    if (_currentCalendar != calendar) {
        return;
    }

    [self clearEvents];
    
    [_cellData release];
    _cellData = [[NSMutableArray alloc] init];
    
    if (events.count) {
        // TODO: make sure this set of events is what we last requested
        NSMutableDictionary *eventsBySection = [NSMutableDictionary dictionary];
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
            NSMutableArray *eventsForCurrentSection = [eventsBySection objectForKey:title];
            if (!eventsForCurrentSection) {
                eventsForCurrentSection = [NSMutableArray array];
                [eventsBySection setObject:eventsForCurrentSection forKey:title];
                [sectionTitles addObject:title];
            }
            [eventsForCurrentSection addObject:event];
        }
        
        for (NSString *sectionTitle in sectionTitles) {
            [_cellData addObject:sectionTitle];
            [_cellData addObjectsFromArray:[eventsBySection objectForKey:sectionTitle]];
        }
    }

    _selectedRow = NSNotFound;
    
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
                                 withRowAnimation:UITableViewRowAnimationMiddle];
            } else {
                animation = UITableViewRowAnimationMiddle;
                [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:oldIndexPath]
                                 withRowAnimation:UITableViewRowAnimationNone];
            }
        }
    }
    
    [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:animation];
    [tableView scrollToRowAtIndexPath:scrollToIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

#define TABLE_TAG 1
#define MAP_TAG 2

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id currentCellData = [_cellData objectAtIndex:indexPath.row];
    if ([currentCellData isKindOfClass:[NSString class]]) {
        static NSString *sectionHeaderCellID = @"Header";
        ScheduleTabletSectionHeaderCell *cell = (ScheduleTabletSectionHeaderCell *)[tableView dequeueReusableCellWithIdentifier:sectionHeaderCellID];
        
        if (!cell) {
            cell = [[[ScheduleTabletSectionHeaderCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                           reuseIdentifier:sectionHeaderCellID] autorelease];
        }
        
        if (indexPath.row == 0) {
            cell.isFirst = YES;
        }
        
        cell.textLabel.text = (NSString *)currentCellData;
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
        
        return cell;
    }
    
    ScheduleCellType cellType = ScheduleCellTypeOther;
    
    if (indexPath.row == _selectedRow) {
        cellType = ScheduleCellSelected;
        
    } else if (indexPath.row == _cellData.count - 1) {
        cellType = ScheduleCellLastInTable;
    }
    
    NSString *cellIdentifier = [NSString stringWithFormat:@"%d", cellType];
    ScheduleTabletTableViewCell *cell = (ScheduleTabletTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[[ScheduleTabletTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                                   reuseIdentifier:cellIdentifier] autorelease];
    }
    
    if (indexPath.row > 0) {
        id previousCellData = [_cellData objectAtIndex:indexPath.row - 1];
        cell.isFirstInSection = [previousCellData isKindOfClass:[NSString class]];
    }
    
    ScheduleEventWrapper *event = [_cellData objectAtIndex:indexPath.row];
    
    cell.scheduleCellType = cellType;
    cell.event = event;
    
    cell.textLabel.text = event.title;
    cell.detailTextLabel.text = [self.dataManager shortDateTimeStringFromDate:event.startDate];
    
    //[[cell.contentView viewWithTag:TABLE_TAG] removeFromSuperview];
    //[[cell.contentView viewWithTag:MAP_TAG] removeFromSuperview];
    
    UIImage *image = nil;
    if ([event isRegistered] || [event isBookmarked]) {
        cell.bookmarkView.hidden = NO;
        image = [UIImage imageWithPathName:@"common/bookmark-ribbon-on"];
        
    } else if (cellType == ScheduleCellSelected) {
        cell.bookmarkView.hidden = NO;
        image = [UIImage imageWithPathName:@"common/bookmark-ribbon-off"];
        
    } else {
        cell.bookmarkView.hidden = YES;
    }
    
    if (image) {
        [cell.bookmarkView setImage:image forState:UIControlStateNormal];
    }
    
    if (cellType == ScheduleCellLastInTable || cellType == ScheduleCellSelected) {
        
        CGFloat width = floor((tableView.frame.size.width - 60) / 2);
        ScheduleDetailTableView *tableView = [self tableViewForCellType:cellType];
        tableView.event = event;
        [cell.contentView addSubview:tableView];
        
        MKMapView *mapView = [self mapViewForCellType:cellType];
        mapView.frame = CGRectMake(280, 60, width, 430);
        if (event.coordinate.latitude) {
            // we only need to check one assuming there will not
            // be any events on the equator
            [mapView addAnnotation:event];
            mapView.region = MKCoordinateRegionMake(event.coordinate, MKCoordinateSpanMake(0.01, 0.01));
        } else {
            [mapView centerAndZoomToDefaultRegion];
        }
        [cell.contentView addSubview:mapView];
        
        // TODO: if we don't do anything in mapViewTapped then just remove this
        // and set mapview userinteractionenabled to false.
        UIControl *control = [[[UIControl alloc] initWithFrame:mapView.frame] autorelease];
        control.backgroundColor = [UIColor clearColor];
        [cell.contentView addSubview:control];
        [control addTarget:self action:@selector(mapViewTapped:) forControlEvents:UIControlEventTouchUpInside];

        tableView.mapView = mapView;
        mapView.delegate = tableView;
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

    } else {
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    
    return cell;
}

- (ScheduleDetailTableView *)tableViewForCellType:(ScheduleCellType)cellType
{
    ScheduleDetailTableView *tableView = nil;
    BOOL needsInitialize = NO;
    if (cellType == ScheduleCellSelected) {
        if (!_tableViewForSelectedCell) {
            _tableViewForSelectedCell = [[ScheduleDetailTableView alloc] initWithFrame:CGRectMake(0, 60, 260, 430)
                                                                                 style:UITableViewStyleGrouped];
            needsInitialize = YES;
        }
        tableView = _tableViewForSelectedCell;
        
    } else if (cellType == ScheduleCellLastInTable) {
        if (!_tableViewForLastCell) {
            _tableViewForLastCell = [[ScheduleDetailTableView alloc] initWithFrame:CGRectMake(0, 60, 260, 430)
                                                                             style:UITableViewStyleGrouped];
            needsInitialize = YES;
        }
        tableView = _tableViewForLastCell;
    }
    
    if (needsInitialize) {
        tableView.backgroundColor = [UIColor clearColor];
        tableView.backgroundView = nil;
        tableView.dataManager = self.dataManager;
        tableView.viewController = [KGO_SHARED_APP_DELEGATE() visibleViewController];
    }
    
    [tableView removeFromSuperview];
    
    return tableView;
}


- (MKMapView *)mapViewForCellType:(ScheduleCellType)cellType
{
    MKMapView *mapView = nil;
    if (cellType == ScheduleCellSelected) {
        if (!_mapViewForSelectedCell) {
            _mapViewForSelectedCell = [[MKMapView alloc] initWithFrame:CGRectMake(280, 60, 260, 430)];
        }
        mapView = _mapViewForSelectedCell;
        
    } else if (cellType == ScheduleCellLastInTable) {
        if (!_mapViewForLastCell) {
            _mapViewForLastCell = [[MKMapView alloc] initWithFrame:CGRectMake(280, 60, 260, 430)];
        }
        mapView = _mapViewForLastCell;
    }
    
    [mapView removeFromSuperview];
    [mapView removeAnnotations:[_mapViewForSelectedCell annotations]];
    
    return mapView;
}

- (void)mapViewTapped:(id)sender
{
    if ([sender isKindOfClass:[UIControl class]]) {
        //NSArray *annotations = [NSArray arrayWithObject:_event];
        //NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:annotations, @"annotations", nil];
        //[KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameHome forModuleTag:MapTag params:params];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id currentCellData = [_cellData objectAtIndex:indexPath.row];
    if ([currentCellData isKindOfClass:[NSString class]]) {
        return 24;
    }
    
    if (indexPath.row == _cellData.count - 1) {
        return 500;
    }
    
    if (indexPath.row == _selectedRow) {
        return 470;
    }
    
    return tableView.rowHeight;
}

#pragma mark Notes

-(void) newNoteForSection: (int) section andRow: (int) row {
    NSArray *eventsForSection = [_currentEventsBySection objectForKey:[_currentSections objectAtIndex:section]];
    ScheduleEventWrapper *event = [eventsForSection objectAtIndex:row];
    
    NSString * noteTitle = [NSString stringWithFormat:@"Note for: %@", event.title];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"title = %@ AND eventIdentifier = %@", noteTitle, event.identifier];
    Note *note = [[[CoreDataManager sharedManager] objectsForEntity:NotesEntityName matchingPredicate:pred] lastObject];
    
    NSDate * dateForNote = [NSDate date];
    
    if (nil != note)
        if (nil != note.date)
            dateForNote = note.date;
    
    if (nil != tempVC)
        [tempVC release];
    
    tempVC = [[[NewNoteViewController alloc] initWithTitleText:noteTitle
                                                          date:dateForNote              
                                                   andDateText:[Note dateToDisplay:dateForNote]
                                                       eventId:event.identifier
                                                     viewWidth:NEWNOTE_WIDTH 
                                                    viewHeight:NEWNOTE_HEIGHT] retain];
    tempVC.viewControllerBackground = self;
    
    UINavigationController *navC = [[[UINavigationController alloc] initWithRootViewController:tempVC] autorelease];
    
    UIBarButtonItem *item = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                           target:self
                                                                           action:@selector(dismissModalViewControllerAnimated:)] autorelease];
    
    tempVC.navigationItem.rightBarButtonItem = item;
    
    navC.modalPresentationStyle =  UIModalPresentationFormSheet;
    [self presentModalViewController:navC animated:YES];
    navC.navigationBar.tintColor = [UIColor blackColor];
    navC.view.userInteractionEnabled = YES;
    
    CGRect frame = navC.view.superview.frame;
    
    frame.size.width = NEWNOTE_WIDTH;
    
    navC.view.superview.frame = frame;
    
    /* navC.view.superview.frame = CGRectMake(NEWNOTE_XOFFSET, 
     NEWNOTE_YOFFSET, 
     NEWNOTE_WIDTH, 
     NEWNOTE_HEIGHT);//it's important to do this after presentModalViewController
     */
}

-(void) newNoteButtonPressedForSelected: (id) sender{
    
    [self newNoteForSection:_selectedIndexPath.section andRow:_selectedIndexPath.row];
}

-(void) newNoteButtonPressedForLast: (id) sender{
    NSArray *eventsForSection = [_currentEventsBySection objectForKey:[_currentSections objectAtIndex:_currentSections.count - 1]];
    
    [self newNoteForSection:_currentSections.count - 1 andRow:eventsForSection.count - 1];
}

-(void) saveNotesState {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"title = %@ AND date = %@", tempVC.titleText, tempVC.date];
    Note *note = [[[CoreDataManager sharedManager] objectsForEntity:NotesEntityName matchingPredicate:pred] lastObject];
    
    if (nil == note) {
        note = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:NotesEntityName];
    }
    
    note.title = tempVC.titleText;
    note.date = tempVC.date;
    note.details = tempVC.textViewString;
    
    if (nil != tempVC.eventIdentifier)
        note.eventIdentifier = tempVC.eventIdentifier;
    
    [[CoreDataManager sharedManager] saveData];
}

- (void) dismissModalViewControllerAnimated:(BOOL)animated {
    
    if (nil != tempVC) {
        [self saveNotesState];
    }
    
    [super dismissModalViewControllerAnimated:YES];
}


#pragma mark
#pragma mark NotesModalViewDelegate 

-(void) deleteNoteWithoutSaving {
    if (nil != tempVC) {
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"title = %@ AND date = %@", tempVC.titleText, tempVC.date];
        Note *note = [[[CoreDataManager sharedManager] objectsForEntity:NotesEntityName matchingPredicate:pred] lastObject];
        
        if (nil != note) {
            [[CoreDataManager sharedManager] deleteObject:note];
            [[CoreDataManager sharedManager] saveData];
        }
    }
    [super dismissModalViewControllerAnimated:YES];
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

@end
