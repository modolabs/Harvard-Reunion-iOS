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
    
    if (!self.dataManager) {
        self.dataManager = [[[ScheduleDataManager alloc] init] autorelease];
        self.dataManager.delegate = self;
        self.dataManager.moduleTag = self.moduleTag;
    }
}

- (void)dealloc
{
    [_myEvents release];
    [super dealloc];
}

- (CellManipulator)tableView:(UITableView *)tableView manipulatorForCellAtIndexPath:(NSIndexPath *)indexPath {
    if (_currentCategories) {
        KGOCalendar *category = [_currentCategories objectAtIndex:indexPath.row];
        NSString *title = category.title;
        
        return [[^(UITableViewCell *cell) {
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.textLabel.text = title;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } copy] autorelease];
        
    } else if (_currentSections && _currentEventsBySection) {
        NSArray *eventsForSection = [_currentEventsBySection objectForKey:[_currentSections objectAtIndex:indexPath.section]];
        ScheduleEventWrapper *event = [eventsForSection objectAtIndex:indexPath.row];
        
        NSString *title = event.title;
        NSString *subtitle = [self.dataManager shortDateTimeStringFromDate:event.startDate];
        UIImage *image = nil;
        if ([event isRegistered] || [event isBookmarked]) {
            image = [[UIImage imageWithPathName:@"common/bookmark-ribbon-on"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
        }
        
        return [[^(UITableViewCell *cell) {
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.textLabel.text = title;
            cell.detailTextLabel.text = subtitle;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = image;
        } copy] autorelease];
    }
    return nil;
}

#pragma mark - Scrolling tabstrip

static bool isOverOneMonth(NSTimeInterval interval) {
    return interval > 31 * 24 * 60 * 60;
}

static bool isOverOneDay(NSTimeInterval interval) {
    return interval > 24 * 60 * 60;
}

static bool isOverOneHour(NSTimeInterval interval) {
    return interval > 60 * 60;
}

- (void)eventsDidChange:(NSArray *)events calendar:(KGOCalendar *)calendar
{
    if (_currentCalendar != calendar) {
        return;
    }
    
    [self clearEvents];
    
    BOOL didHaveMyEvents = _myEvents != nil;
    
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
        
        for (ScheduleEventWrapper *event in events) {
            NSString *title = [formatter stringFromDate:event.startDate];
            NSMutableArray *eventsForCurrentSection = [eventsBySection objectForKey:title];
            if (!eventsForCurrentSection) {
                eventsForCurrentSection = [NSMutableArray array];
                [eventsBySection setObject:eventsForCurrentSection forKey:title];
                [sectionTitles addObject:title];
            }
            [eventsForCurrentSection addObject:event];
            
            if ([event isRegistered] || [event isBookmarked]) {
                if (!_myEvents) {
                    _myEvents = [[NSMutableDictionary alloc] init];
                }
                [_myEvents setObject:event forKey:event.identifier];
            }
        }
        
        _currentSections = [sectionTitles copy];
        _currentEventsBySection = [eventsBySection copy];
    }
    
    if (!didHaveMyEvents && _myEvents) {
        _didAddNewCategory = YES;
        KGOScrollingTabstrip *newTabstrip = [[[KGOScrollingTabstrip alloc] initWithFrame:_tabstrip.frame] autorelease];
        newTabstrip.delegate = self;
        [_tabstrip removeFromSuperview];
        _tabstrip = newTabstrip;
        [self.view addSubview:newTabstrip];
        [self setupTabstripButtons];
    }
    
    [_loadingView stopAnimating];
    self.tableView.hidden = NO;
    [self reloadDataForTableView:self.tableView];
}

- (void)tabstrip:(KGOScrollingTabstrip *)tabstrip clickedButtonAtIndex:(NSUInteger)index
{
    if (index != _currentGroupIndex) {
        [self removeTableView:self.tableView];
        [_loadingView startAnimating];
        
        _currentGroupIndex = index;
        if (_myEvents.count) {
            index--;
        }

        if (index == -1) {
            [self eventsDidChange:[_myEvents allValues] calendar:_currentCalendar];
            
        } else {        
            [self.dataManager selectGroupAtIndex:index];
            KGOCalendarGroup *group = [self.dataManager currentGroup];
            [self groupDataDidChange:group];
        }
    }
}

- (void)setupTabstripButtons
{
    _tabstrip.showsSearchButton = NO;

    NSInteger selectTabIndex = _currentGroupIndex;
    if (selectTabIndex == NSNotFound) {
        selectTabIndex = 0;
    }
    if (_didAddNewCategory) {
        selectTabIndex++;
        _didAddNewCategory = NO;
    }
    
    if (_myEvents.count) {
        [_tabstrip addButtonWithTitle:@"My Events"];
    }
    
    for (NSInteger i = 0; i < _groupTitles.count; i++) {
        NSString *buttonTitle = [_groupTitles objectAtIndex:i];
        [_tabstrip addButtonWithTitle:buttonTitle];
    }
    [_tabstrip setNeedsLayout];
    [_tabstrip selectButtonAtIndex:selectTabIndex];
}

@end
