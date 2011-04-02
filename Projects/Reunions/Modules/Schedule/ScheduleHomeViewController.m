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

@end
