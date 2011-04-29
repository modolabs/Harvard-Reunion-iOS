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

#pragma mark - Table view overrides

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *eventsForSection = [_currentEventsBySection objectForKey:[_currentSections objectAtIndex:indexPath.section]];
    ScheduleEventWrapper *event = [eventsForSection objectAtIndex:indexPath.row];
    
    NSString *title = event.title;
    NSString *subtitle = [self.dataManager shortDateTimeStringFromDate:event.startDate];
    UIImage *image = nil;
    if ([event isRegistered] || [event isBookmarked]) {
        image = [UIImage imageWithPathName:@"modules/schedule/list-bookmark"];
    }
    
    UITableViewCellStyle style = UITableViewCellStyleDefault;
    if (subtitle && [subtitle length]) {
        style = UITableViewCellStyleSubtitle;
    }
    NSString *cellIdentifier = [NSString stringWithFormat:@"%d", style];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:style reuseIdentifier:cellIdentifier] autorelease];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.imageView.image = image;
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    
    NSInteger titleTag = 60;
    NSInteger subtitleTag = 61;
    
    // adjust for icon, padding and accessory
    CGFloat width = tableView.frame.size.width - 20 - (image ? 24 : 0) - 35 /* accessory */; 
    CGFloat x = image ? 34 : 10;
    CGFloat y = 10;
    
    UIFont *titleFont = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListTitle];
    UILabel *titleLabel = (UILabel *)[cell.contentView viewWithTag:titleTag];
    if (!titleLabel) {
        titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(x, y, width, titleFont.lineHeight)] autorelease];
        titleLabel.font = titleFont;
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.numberOfLines = 2;
        titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
        titleLabel.tag = titleTag;
    } 
    CGSize titleSize = [title sizeWithFont:titleFont
                         constrainedToSize:CGSizeMake(width, titleFont.lineHeight * 2)
                             lineBreakMode:UILineBreakModeTailTruncation];
    CGRect titleFrame = titleLabel.frame;
    titleFrame.size.height = titleSize.height;
    titleFrame.origin.x = x;
    titleLabel.frame = titleFrame;
    titleLabel.text = title;
    [cell.contentView addSubview:titleLabel];
    y += titleSize.height + 1;
    
    if (subtitle && [subtitle length]) {
        UIFont *subtitleFont = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListSubtitle];
        UILabel *subtitleLabel = (UILabel *)[cell.contentView viewWithTag:subtitleTag];
        if (!subtitleLabel) {
            subtitleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(x, y, width, subtitleFont.lineHeight)] autorelease];
            subtitleLabel.font = subtitleFont;
            subtitleLabel.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyNavListSubtitle];
            subtitleLabel.backgroundColor = [UIColor clearColor];
            subtitleLabel.numberOfLines = 1;
            subtitleLabel.lineBreakMode = UILineBreakModeTailTruncation;
            subtitleLabel.tag = subtitleTag;
        }
        CGRect subtitleFrame = subtitleLabel.frame;
        subtitleFrame.origin.x = x;
        subtitleFrame.origin.y = y;
        subtitleLabel.frame = subtitleFrame;
        subtitleLabel.text = subtitle;

        [cell.contentView addSubview:subtitleLabel];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *eventsForSection = [_currentEventsBySection objectForKey:[_currentSections objectAtIndex:indexPath.section]];
    ScheduleEventWrapper *event = [eventsForSection objectAtIndex:indexPath.row];
    
    NSString *title = event.title;
    NSString *subtitle = [self.dataManager shortDateTimeStringFromDate:event.startDate];
    UIImage *image = nil;
    if ([event isRegistered] || [event isBookmarked]) {
        image = [UIImage imageWithPathName:@"modules/schedule/list-bookmark"];
    }
    
    // adjust for icon, padding and accessory
    CGFloat width = tableView.frame.size.width - 20 - (image ? 24 : 0) - 35 /* accessory */; 
    CGFloat height = 22;
    
    UIFont *titleFont = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListTitle];
    CGSize titleSize = [title sizeWithFont:titleFont
                         constrainedToSize:CGSizeMake(width, titleFont.lineHeight * 2)
                             lineBreakMode:UILineBreakModeTailTruncation];
    height += titleSize.height;
    
    if (subtitle && [subtitle length]) {
        UIFont *subtitleFont = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListSubtitle];
        CGSize subtitleSize = [subtitle sizeWithFont:subtitleFont
                                   constrainedToSize:CGSizeMake(width, subtitleFont.lineHeight)
                                       lineBreakMode:UILineBreakModeTailTruncation];
        height += subtitleSize.height + 1;
    }
    
    return height;
    
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
