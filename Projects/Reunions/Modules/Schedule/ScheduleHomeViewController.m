#import "ScheduleHomeViewController.h"
#import "ScheduleDataManager.h"
#import "ScheduleEventWrapper.h"
#import "UIKit+KGOAdditions.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "ScheduleDetailTableView.h"
#import "ScheduleTabletTableViewCell.h"
#import <QuartzCore/QuartzCore.h>

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
    
    KGONavigationStyle navStyle = [KGO_SHARED_APP_DELEGATE() navigationStyle];
    _isTablet = (navStyle == KGONavigationStyleTabletSidebar);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view bringSubviewToFront:_tabstrip];
}

- (void)dealloc
{
    [_myEvents release];
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    // since we don't get notified when user (un)bookmarks an event
    NSMutableArray *allEvents = [NSMutableArray array];
    for (NSArray *events in [_currentEventsBySection allValues]) {
        [allEvents addObjectsFromArray:events];
    }
    [self eventsDidChange:allEvents calendar:_currentCalendar];
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
    
    if (_isTablet) {
        frame.origin.x += 8;
        frame.origin.y += 8;
        frame.size.width -= 16;
        frame.size.height -= 16;

        self.tableView = [[[UITableView alloc] initWithFrame:frame style:style] autorelease];
        self.tableView.backgroundColor = [UIColor clearColor];
        self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        [self.view addSubview:self.tableView];
    } else {
        self.tableView = [self addTableViewWithFrame:frame style:style];
    }
}

#pragma mark - Table view overrides

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (_isTablet) {
        return [[[KGOTheme sharedTheme] fontForPlainSectionHeader] lineHeight] + 5;
    }
    return [super tableView:tableView heightForHeaderInSection:section];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (_isTablet) {
        NSString *title = [_currentSections objectAtIndex:section];
        UIFont *font = [[KGOTheme sharedTheme] fontForPlainSectionHeader];
        CGSize size = [title sizeWithFont:font];
        
        CGFloat hPadding = 10.0f;
        CGFloat viewHeight = font.lineHeight + 5.0f;
        
        UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(hPadding + 8,
                                                                    floor((viewHeight - size.height) / 2),
                                                                    tableView.bounds.size.width - 8 - hPadding * 2,
                                                                    size.height)] autorelease];
        
        label.textColor = [[KGOTheme sharedTheme] textColorForPlainSectionHeader];
        label.backgroundColor = [UIColor clearColor];
        label.text = title;
        label.font = font;
        
        UIView *labelContainer = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, viewHeight)] autorelease];
        labelContainer.backgroundColor = [UIColor clearColor];
        labelContainer.opaque = NO;

        UIImageView *labelBackground = [[[UIImageView alloc] initWithFrame:CGRectMake(8, 0,
                                                                                      tableView.frame.size.width - 8,
                                                                                      viewHeight + 5)] autorelease];
        labelBackground.image = [[UIImage imageWithPathName:@"modules/schedule/fakeheader"] stretchableImageWithLeftCapWidth:5 topCapHeight:0];
        labelBackground.layer.cornerRadius = 5;
        labelBackground.opaque = NO;
        
        [labelContainer addSubview:labelBackground];
        [labelContainer addSubview:label];
        
        return labelContainer;
    }

    return [super tableView:tableView viewForHeaderInSection:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (_isTablet) {
        return nil;
    }
    return [super tableView:tableView titleForHeaderInSection:section];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_isTablet) {
        
        if (_selectedIndexPath && _selectedIndexPath.row == indexPath.row && _selectedIndexPath.section == indexPath.section) {
            return;
        }
        
        NSIndexPath *oldIndexPath = _selectedIndexPath;
        
        [_selectedIndexPath release];
        _selectedIndexPath = [indexPath retain];
        
        NSMutableArray *needsRefresh = [NSMutableArray array];
        
        if (oldIndexPath) {
            [needsRefresh addObject:oldIndexPath];
        }
        if (_selectedIndexPath.row > 0) {
            NSIndexPath *aboveIndexPath = [NSIndexPath indexPathForRow:_selectedIndexPath.row-1 inSection:_selectedIndexPath.section];
            if (aboveIndexPath.row != oldIndexPath.row || aboveIndexPath.section != oldIndexPath.section) {            
                [needsRefresh addObject:aboveIndexPath];
            }
        }
        if (needsRefresh.count) {
            [tableView reloadRowsAtIndexPaths:needsRefresh withRowAnimation:UITableViewRowAnimationNone];
        }
        
        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:_selectedIndexPath] withRowAnimation:UITableViewRowAnimationLeft];
        
    } else {
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_isTablet) {

        ScheduleCellType cellType = ScheduleCellTypeOther;
        
        NSArray *eventsForSection = [_currentEventsBySection objectForKey:[_currentSections objectAtIndex:indexPath.section]];
        
        BOOL needsFakeBorder = NO;
        BOOL isLastInSection = NO;
        BOOL isLastInTable = NO;
        if (_selectedIndexPath && indexPath.section == _selectedIndexPath.section) {
            if (indexPath.row == _selectedIndexPath.row) {
                needsFakeBorder = YES;
                cellType = ScheduleCellSelected;
            
            } else if (indexPath.row == _selectedIndexPath.row - 1) {
                needsFakeBorder = YES;
                cellType = ScheduleCellAboveSelectedRow;
            }
            
        } else if (indexPath.row == eventsForSection.count - 1) {
            if (indexPath.section == _currentSections.count - 1) {
                isLastInTable = YES;
                cellType = ScheduleCellLastInTable;
            
            } else {
                isLastInSection = YES;
                cellType = ScheduleCellLastInSection;
            }
        }
        
        NSString *cellIdentifier = [NSString stringWithFormat:@"%d", cellType];
        ScheduleTabletTableViewCell *cell = (ScheduleTabletTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if (!cell) {
            cell = [[[ScheduleTabletTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                                       reuseIdentifier:cellIdentifier] autorelease];
        }
        
        cell.scheduleCellType = cellType;
        cell.isFirstInSection = (indexPath.row == 0);
        cell.tableView = self.tableView;
        
        ScheduleEventWrapper *event = [eventsForSection objectAtIndex:indexPath.row];
        
        [[cell.contentView viewWithTag:1] removeFromSuperview];
        [[cell.contentView viewWithTag:2] removeFromSuperview];

        switch (cellType) {
            case ScheduleCellSelected:
            case ScheduleCellLastInTable:
            {
                CGFloat width = floor((tableView.frame.size.width - 30) / 2);
                ScheduleDetailTableView *tableView = (ScheduleDetailTableView *)[cell.contentView viewWithTag:1];
                if (!tableView) {
                    tableView = [[[ScheduleDetailTableView alloc] initWithFrame:CGRectMake(10, 10, width, 480)
                                                                          style:UITableViewStyleGrouped] autorelease];
                    tableView.event = event;
                    tableView.backgroundColor = [UIColor clearColor];
                    tableView.tag = 1;
                    [cell.contentView addSubview:tableView];
                }
                
                MKMapView *mapView = (MKMapView *)[cell.contentView viewWithTag:2];
                if (!mapView) {
                    [[[MKMapView alloc] initWithFrame:CGRectMake(300, 10, width, 480)] autorelease];
                    mapView.tag = 2;
                    [cell.contentView addSubview:mapView];
                }
                
                break;
            }
            default:
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                cell.textLabel.text = event.title;
                cell.detailTextLabel.text = [self.dataManager shortDateTimeStringFromDate:event.startDate];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                if ([event isRegistered] || [event isBookmarked]) {
                    cell.imageView.image = [UIImage imageWithPathName:@"modules/schedule/list-bookmark"];
                } else {
                    cell.imageView.image = nil;
                }
                break;
        }

        return cell;
    
    }
    
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_isTablet) {
        
        if (_selectedIndexPath && indexPath.section == _selectedIndexPath.section && indexPath.row == _selectedIndexPath.row) {
            return 470;
        }
        
        NSArray *eventsForSection = [_currentEventsBySection objectForKey:[_currentSections objectAtIndex:indexPath.section]];
        if (indexPath.row == eventsForSection.count - 1 && indexPath.section == _currentSections.count - 1) {
            return 500; // last row
        }
    }
    
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
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
