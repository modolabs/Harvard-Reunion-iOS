#import "ScheduleHomeViewController.h"
#import "ScheduleDataManager.h"
#import "ScheduleEventWrapper.h"
#import "UIKit+KGOAdditions.h"

@implementation ScheduleHomeViewController

- (void)loadView
{
    [super loadView];
    [_datePager removeFromSuperview];
    _datePager = nil;

    // TODO: this shouldn't be necessary
    if (!self.dataManager) {
        self.dataManager = [[[ScheduleDataManager alloc] init] autorelease];
        self.dataManager.delegate = self;
        self.dataManager.moduleTag = self.moduleTag;
    }
    
    self.view.backgroundColor = [UIColor clearColor];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view bringSubviewToFront:_tabstrip];
}

- (void)dealloc
{
    self.dataManager.delegate = nil;
    [_myEvents release];
    _myEvents = nil;
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        // since we don't get notified when user (un)bookmarks an event
        NSMutableArray *allEvents = [NSMutableArray array];
        for (NSArray *events in [_currentEventsBySection allValues]) {
            [allEvents addObjectsFromArray:events];
        }
        [self eventsDidChange:allEvents calendar:_currentCalendar];
    }

    [super viewWillAppear:animated];
}

- (void)loadTableViewWithStyle:(UITableViewStyle)style
{
    CGRect frame = self.view.frame;
    if (!_datePager.hidden && [_datePager isDescendantOfView:self.view]) {
        frame.origin.y += _datePager.frame.size.height;
        frame.size.height -= _datePager.frame.size.height;
    }
    if (!_tabstrip.hidden && [_tabstrip isDescendantOfView:self.view]) {
        frame.origin.y += _tabstrip.frame.size.height;
        frame.size.height -= _tabstrip.frame.size.height;
    }
    
    self.tableView = [self addTableViewWithFrame:frame style:style];
    self.tableView.rowHeight += 2;
}

#pragma mark - KGOTableViewDataSource

- (CellManipulator)tableView:(UITableView *)tableView manipulatorForCellAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *eventsForSection = [_currentEventsBySection objectForKey:[_currentSections objectAtIndex:indexPath.section]];
    
    ScheduleEventWrapper *event = [eventsForSection objectAtIndex:indexPath.row];
    
    NSString *title = event.title;
    NSString *subtitle = [self.dataManager shortDateTimeStringFromDate:event.startDate];
    UIImage *image = nil;
    if ([event isRegistered] || [event isBookmarked]) {
        image = [UIImage imageWithPathName:@"modules/schedule/list-bookmark"];
    }
    
    return [[^(UITableViewCell *cell) {
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.textLabel.text = title;
        cell.detailTextLabel.text = subtitle;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.imageView.image = image;
    } copy] autorelease];
}

- (void)clearEvents
{
    [super clearEvents];
    
    [_myEvents release];
    _myEvents = nil;
}

#pragma mark - Scrolling tabstrip

- (void)eventsDidChange:(NSArray *)events calendar:(KGOCalendar *)calendar
{
    if (_currentCalendar != calendar) {
        return;
    }
    
    [self clearEvents];
    
    BOOL isViewingMyEvents = _currentGroupIndex == 0;
    
    if (events.count) {
        // TODO: make sure this set of events is what we last requested
        NSMutableDictionary *eventsBySection = [NSMutableDictionary dictionary];
        NSMutableArray *sectionTitles = [NSMutableArray array];
        NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:YES]];
        NSArray *sortedEvents = [events sortedArrayUsingDescriptors:sortDescriptors];
        ScheduleEventWrapper *firstEvent = [sortedEvents objectAtIndex:0];
        ScheduleEventWrapper *lastEvent = [sortedEvents lastObject];
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
        
        for (ScheduleEventWrapper *event in sortedEvents) {
            DLog(@"adding event to section %@", event);
            NSString *title = [formatter stringFromDate:event.startDate];
            NSMutableArray *eventsForCurrentSection = [eventsBySection objectForKey:title];
            if (!eventsForCurrentSection) {
                eventsForCurrentSection = [NSMutableArray array];
                [eventsBySection setObject:eventsForCurrentSection forKey:title];
                [sectionTitles addObject:title];
            }

            if ([event isRegistered] || [event isBookmarked]) {
                if (!_myEvents) {
                    _myEvents = [[NSMutableDictionary alloc] init];
                }
                [_myEvents setObject:event forKey:event.identifier];
                
            } else {
                [_myEvents removeObjectForKey:event.identifier];
            }

            if (!isViewingMyEvents || [event isRegistered] || [event isBookmarked]) {
                [eventsForCurrentSection addObject:event];
            }
        }
        
        [_currentSections release];
        _currentSections = [sectionTitles copy];
 
        [_currentEventsBySection release];
        _currentEventsBySection = [eventsBySection copy];
    }
    
    [_loadingView stopAnimating];
    self.tableView.hidden = NO;
    [self reloadDataForTableView:self.tableView];
}

- (void)tabstrip:(KGOScrollingTabstrip *)tabstrip clickedButtonAtIndex:(NSUInteger)index
{
    if (index != _currentGroupIndex) {
        _currentGroupIndex = index;

        if (index == 0) {
            [self eventsDidChange:[_myEvents allValues] calendar:_currentCalendar];
            
        } else {
            [self removeTableView:self.tableView];
            [_loadingView startAnimating];
            [self.dataManager selectGroupAtIndex:index - 1];
            KGOCalendarGroup *group = [self.dataManager currentGroup];
            [self groupDataDidChange:group];
        }
    }
}

- (void)setupTabstripButtons
{
    _tabstrip.showsSearchButton = NO;

    NSInteger selectTabIndex = _currentGroupIndex;
    if (selectTabIndex == NSNotFound && _groupTitles.count) {
        selectTabIndex = 1;
    }
    
    [_tabstrip addButtonWithTitle:@"My Schedule"];
    
    for (NSInteger i = 0; i < _groupTitles.count; i++) {
        NSString *buttonTitle = [_groupTitles objectAtIndex:i];
        [_tabstrip addButtonWithTitle:buttonTitle];
    }
    [_tabstrip setNeedsLayout];
    [_tabstrip selectButtonAtIndex:selectTabIndex];
}

@end
