
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import "ReunionMapTabletDetailController.h"
#import "UIKit+KGOAdditions.h"
#import <QuartzCore/QuartzCore.h>
#import "KGOSidebarFrameViewController.h"
#import "ScheduleEventWrapper.h"
#import "KGOPlacemark.h"
#import "ReunionMapTabletHeaderView.h"

#define IPAD_TABLEVIEW_ORIGIN_Y 500
#define CLOSE_BUTTON_TAG 15

@implementation ReunionMapTabletDetailController

- (void)loadView
{
    [super loadView];
    
    _currentTableWidth = 0;
    
    _scrollView = [[[UIScrollView alloc] initWithFrame:self.view.bounds] autorelease];
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _scrollView.bounces = NO;
    [_scrollView addSubview:self.tableView];
    _scrollView.delegate = self;
    _scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width, 500 + self.tableView.frame.size.height);
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.clipsToBounds = NO;
    
    CGRect frame = self.tableView.frame;
    frame.origin.y = IPAD_TABLEVIEW_ORIGIN_Y;
    self.tableView.frame = frame;
    self.tableView.layer.cornerRadius = 5;
    
    UIView *view = [[[UIView alloc] initWithFrame:self.tableView.bounds] autorelease];
    view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    view.layer.cornerRadius = 5;
    view.backgroundColor = [UIColor colorWithHexString:@"F3F2F2"];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.backgroundView = view;
    
    self.tableView.scrollEnabled = NO;
    self.tableView.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.tableView.layer.shadowOpacity = 0.7;
    self.tableView.layer.shadowRadius = 4;
    self.tableView.clipsToBounds = NO;
    self.tableView.separatorColor = [UIColor colorWithHexString:@"#AAA9A9"];
    
    [self.view addSubview:_scrollView];
    [_scrollView addSubview:self.tableView];
}


- (void)viewDidLoad
{
    self.view.backgroundColor = [UIColor clearColor];
    
    [self loadAnnotationContent]; // load annotation before inspecting it
    
    if ([self.annotation isKindOfClass:[KGOPlacemark class]]) {
        self.title = @"Building Detail";
    } else if ([self.annotation isKindOfClass:[ScheduleEventWrapper class]]) {
        self.title = @"Event Location";
    }
    
    if (self.pager) {
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:self.pager] autorelease];
    }
    
    if (!_headerView) {
        _headerView = [[ReunionMapTabletHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 1)];
        _headerView.delegate = self;
        _headerView.showsBookmarkButton = YES;
    }
    _headerView.detailItem = self.annotation;
    self.tableView.tableHeaderView = _headerView;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // make sure at least 400px of the table height is visible
    [_scrollView scrollRectToVisible:CGRectMake(0, 500, 1, 400) animated:YES];
}

- (void)loadDetailSection
{
    // set up photo
    _canShowThumbnail = NO;
    
    if (_image || _imageURL) {
        if (!_thumbView) {
            _thumbView = [[MITThumbnailView alloc] initWithFrame:CGRectMake(10, 0, 1, 1)];
            _thumbView.layer.borderColor = [[UIColor grayColor] CGColor];
            _thumbView.layer.borderWidth = 1;
            _thumbView.clipsToBounds = NO;
            _thumbView.delegate = self;
        }
        
        if (_image) {
            CGFloat maxWidth = self.tableView.frame.size.width - 40;
            CGFloat ratio = maxWidth / _image.size.width;
            CGRect frame = _thumbView.frame;
            frame.size = CGSizeMake(floor(ratio * _image.size.width), floor(ratio * _image.size.height));
            _thumbView.frame = frame;
            _thumbView.imageData = UIImagePNGRepresentation(_image);
            [_thumbView displayImage];
            _canShowThumbnail = YES;
            
        } else {
            _thumbView.imageURL = _imageURL;
            _thumbView.imageData = nil;
            [_thumbView loadImage];
        }
    }
    
    NSArray *userInfo = [NSKeyedUnarchiver unarchiveObjectWithData:self.placemark.userInfo];
    if ([userInfo isKindOfClass:[NSArray class]]) {
        [_detailFields release];
        _detailFields = [userInfo retain];
    }
}

- (void)thumbnail:(MITThumbnailView *)thumbnail didLoadData:(NSData *)data
{
    _canShowThumbnail = YES;
    
    // this is like super but the width is larger
    if ([thumbnail.imageURL isEqualToString:self.placemark.photoURL]) {
        self.placemark.photo = data;
        
        UIImage *image = [UIImage imageWithData:data];
        CGFloat maxWidth = self.tableView.frame.size.width - 20;
        CGFloat ratio = maxWidth / image.size.width;
        CGRect frame = thumbnail.frame;
        frame.size = CGSizeMake(maxWidth, floor(ratio * image.size.height));
        thumbnail.frame = frame;
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:_detailSection]
                      withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)dealloc
{
    [_detailFields release];
    [super dealloc];
}

#pragma mark scroll view

- (void)updateScrollView
{
    NSInteger count = [self numberOfSectionsInTableView:self.tableView];
    CGRect rect = [self.tableView rectForSection:count-1];
    CGFloat height = rect.origin.y + rect.size.height;
    
    _scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width, IPAD_TABLEVIEW_ORIGIN_Y + height);
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self updateScrollView];
}

#pragma mark table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([self.annotation isKindOfClass:[ScheduleEventWrapper class]] && _placemarkInfo) {
        return 3;
    }
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_currentTableWidth && _currentTableWidth != tableView.frame.size.width) {
        [self loadDetailSection];
    }
    _currentTableWidth = tableView.frame.size.width;

    if (section == _detailSection) {
        return _detailFields.count;
    }
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == _detailSection && _canShowThumbnail) {
        return _thumbView.frame.size.height + 10;
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == _detailSection && _canShowThumbnail) {
        
        UIView *containerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width,
                                                                          _thumbView.frame.size.height)] autorelease];
        [containerView addSubview:_thumbView];

        return containerView;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return tableView.rowHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = [NSString stringWithFormat:@"%d", indexPath.section];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
        cell.backgroundColor = [UIColor colorWithHexString:@"#E3E1E1"];
    }
    
    if (indexPath.section == _eventSection) {
        cell.textLabel.text = @"More event info";
        cell.accessoryView = [[KGOTheme sharedTheme] accessoryViewForType:KGOAccessoryTypeChevron];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        
    } else if (indexPath.section == _googleSection) {
        cell.textLabel.text = @"View Location in Google Maps";
        cell.accessoryView = [[KGOTheme sharedTheme] accessoryViewForType:KGOAccessoryTypeExternal];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        
    } else {
        NSDictionary *cellInfo = [_detailFields objectAtIndex:indexPath.row];
        NSString *labelText = [cellInfo objectForKey:@"label"];
        cell.textLabel.text = labelText;
        cell.textLabel.font = [UIFont boldSystemFontOfSize:17];

        CGSize size = [labelText sizeWithFont:cell.textLabel.font];
        
        UILabel *label = (UILabel *)[cell.contentView viewWithTag:888];
        if (!label) {
            label = [[[UILabel alloc] initWithFrame:CGRectMake(size.width + 15, 10,
                                                               tableView.frame.size.width - 45 - size.width,
                                                               size.height)] autorelease];
            label.textColor = [UIColor colorWithWhite:0.2 alpha:1];
            label.tag = 888;
            label.backgroundColor = [UIColor clearColor];
            [cell.contentView addSubview:label];

        } else {
            label.frame = CGRectMake(size.width + 20, 10,
                                     tableView.frame.size.width - 40 - size.width,
                                     size.height);
        }
        label.text = [cellInfo objectForKey:@"title"];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == _detailSection) {
        CGSize size = [cell.textLabel.text sizeWithFont:cell.textLabel.font];
        CGRect frame = cell.textLabel.frame;
        frame.size = size;
        cell.textLabel.frame = frame;
        
        CGFloat width = cell.frame.size.width - frame.size.width - 30;
        frame = cell.detailTextLabel.frame;
        frame.origin.x = cell.textLabel.frame.size.width + 20;
        frame.size.width = width;
        cell.detailTextLabel.frame = frame;
    }
}

@end
