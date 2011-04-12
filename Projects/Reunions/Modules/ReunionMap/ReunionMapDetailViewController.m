#import "ReunionMapDetailViewController.h"
#import "KGOPlacemark.h"
#import "KGOTheme.h"
#import "KGOHTMLTemplate.h"
#import "ScheduleEventWrapper.h"
#import <MapKit/MKAnnotation.h>

@implementation ReunionMapDetailViewController

//@synthesize placemark,
@synthesize annotation, pager;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark KGODetailPager

- (void)pager:(KGODetailPager*)pager showContentForPage:(id<KGOSearchResult>)content {
    if ([content isKindOfClass:[KGOPlacemark class]]) {
        //self.placemark = (KGOPlacemark *)content;
        self.annotation = (id<MKAnnotation, KGOSearchResult>)content;
        
        _webViewHeight = 0;
        _thumbViewHeight = 0;
        
        //_headerView.detailItem = self.placemark;
        _headerView.detailItem = self.annotation;
        [self.tableView reloadData];
    }
}

#pragma mark - Table header

- (void)headerViewFrameDidChange:(KGODetailPageHeaderView *)headerView
{
    self.tableView.tableHeaderView = _headerView;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    
    if (self.pager) {
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:self.pager] autorelease];
    }
    
    if (!_headerView) {
        _headerView = [[ReunionDetailPageHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 1)];
        _headerView.delegate = self;
        _headerView.showsBookmarkButton = YES;
    }
    //_headerView.detailItem = self.placemark;
    _headerView.detailItem = self.annotation;
    self.tableView.tableHeaderView = _headerView;
    
    _webViewHeight = 0;
    _thumbViewHeight = 0;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = tableView.rowHeight;
    if (indexPath.section == 1) {
        height = _webViewHeight + 20;
        if (_thumbViewHeight) {
            height += _thumbViewHeight + 10;
        }
    }
    return height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = [NSString stringWithFormat:@"%d", indexPath.section];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
    }
    
    switch (indexPath.section) {
        case 0:
            cell.textLabel.text = @"View Location in Google Maps";
            cell.accessoryView = [[KGOTheme sharedTheme] accessoryViewForType:KGOAccessoryTypeExternal];
            break;
        case 1:
        {
            MITThumbnailView *thumbView = (MITThumbnailView *)[cell.contentView viewWithTag:2];

            UIImage *image = nil;
            NSString *imageURL = nil;
            if ([self.annotation isKindOfClass:[KGOPlacemark class]]) {
                image = [UIImage imageWithData:[(KGOPlacemark *)self.annotation photo]];
                imageURL = [(KGOPlacemark *)self.annotation photoURL];
            } else if ([self.annotation isKindOfClass:[ScheduleEventWrapper class]]) {
                
            }
            
            if (image || imageURL) {
                if (!thumbView) {
                    thumbView = [[[MITThumbnailView alloc] initWithFrame:CGRectMake(10, 10, 1, 1)] autorelease];
                    thumbView.tag = 2;
                    thumbView.delegate = self;
                    [cell.contentView addSubview:thumbView];
                }

                if (image) {
                    CGFloat maxWidth = tableView.frame.size.width - 40;
                    CGFloat ratio = maxWidth / image.size.width;
                    CGRect frame = thumbView.frame;
                    frame.size = CGSizeMake(floor(ratio * image.size.width), floor(ratio * image.size.height));
                    thumbView.frame = frame;
                    _thumbViewHeight = frame.size.height;
                    thumbView.imageData = UIImagePNGRepresentation(image);
                    [thumbView displayImage];
                    
                } else {
                    thumbView.imageURL = imageURL;
                    [thumbView loadImage];
                }
            }
            
            NSString *info = nil;
            if ([self.annotation isKindOfClass:[KGOPlacemark class]]) {
                info = [(KGOPlacemark *)self.annotation info];

            } else if ([self.annotation isKindOfClass:[ScheduleEventWrapper class]]
                       && [(ScheduleEventWrapper *)self.annotation placemarkID]
            ) {
                info = [NSString stringWithFormat:@"Building Number: %@", [(ScheduleEventWrapper *)self.annotation placemarkID]];
            }
            
            UIWebView *webView = (UIWebView *)[cell.contentView viewWithTag:1];
            if (!webView) {
                CGRect webViewFrame = CGRectMake(10, 10, tableView.frame.size.width - 40, 1);
                webView = [[[UIWebView alloc] initWithFrame:webViewFrame] autorelease];
                webView.tag = 1;
                webView.delegate = self;
                [cell.contentView addSubview:webView];
            }
            if (!_htmlTemplate) {
                _htmlTemplate = [[KGOHTMLTemplate templateWithPathName:@"modules/map/detail.html"] retain];
            }
            
            CGFloat y = thumbView.frame.origin.y + thumbView.frame.size.height;
            if (y > 11) {
                webView.frame = CGRectMake(10, y + 10, webView.frame.size.width, webView.frame.size.height);
            }
            
            NSDictionary *replacements = [NSDictionary dictionaryWithObjectsAndKeys:info, @"BODY", nil];
            NSString *string = [_htmlTemplate stringWithReplacements:replacements];
            [webView loadHTMLString:string baseURL:nil];
            break;
        }
        default:
            break;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *search = nil;
    
    if (self.annotation.coordinate.latitude || self.annotation.coordinate.longitude) {
        search = [NSString stringWithFormat:@"%.5f,%.5f", self.annotation.coordinate.latitude, self.annotation.coordinate.longitude];
    } else if ([self.annotation isKindOfClass:[KGOPlacemark class]] && [(KGOPlacemark *)self.annotation street]) {
        search = [(KGOPlacemark *)self.annotation street];
    } else if ([self.annotation isKindOfClass:[ScheduleEventWrapper class]] && [(ScheduleEventWrapper *)self.annotation location]) {
        search = [(ScheduleEventWrapper *)self.annotation location];
    }
    
    NSString *urlString = [NSString stringWithFormat:@"http://maps.google.com/maps?q=%@", [search stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

    NSURL *url = [NSURL URLWithString:urlString];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Web view delegate

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    CGRect frame = webView.frame;
    CGSize size = [webView sizeThatFits:frame.size];
    if (size.height != frame.size.height) {
        frame.size.height = size.height;
        webView.frame = frame;
        _webViewHeight = frame.size.height;
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1]
                      withRowAnimation:UITableViewRowAnimationNone];
    }
}

#pragma mark - Thumbnail delegate

- (void)thumbnail:(MITThumbnailView *)thumbnail didLoadData:(NSData *)data
{
    if ([self.annotation isKindOfClass:[KGOPlacemark class]]) {
        KGOPlacemark *placemark = (KGOPlacemark *)self.annotation;
        
        if ([thumbnail.imageURL isEqualToString:placemark.photoURL]) {
            placemark.photo = data;
            
            UIImage *image = [UIImage imageWithData:data];
            CGFloat maxWidth = self.view.frame.size.width - 40;
            CGFloat ratio = maxWidth / image.size.width;
            CGRect frame = thumbnail.frame;
            frame.size = CGSizeMake(floor(ratio * image.size.width), floor(ratio * image.size.height));
            thumbnail.frame = frame;
            _thumbViewHeight = frame.size.height;
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1]
                          withRowAnimation:UITableViewRowAnimationNone];
        }
        
    }
}

@end
