
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import "ScheduleDetailViewController.h"
#import "ScheduleDetailTableView.h"
#import "KGOTheme.h"

@implementation ScheduleDetailViewController

- (void)setupTableView
{
    if (!_tableView) {
        CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
        _tableView = [[ScheduleDetailTableView alloc] initWithFrame:frame style:UITableViewStyleGrouped];
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.dataManager = self.dataManager;
        _tableView.viewController = self;
        _tableView.rowHeight += 2;
        
        [self.view addSubview:_tableView];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)dealloc
{
    [super dealloc];
}

@end
