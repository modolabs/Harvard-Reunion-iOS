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
    [_webView release];
    [_thumbView release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark KGODetailPager

- (void)loadAnnotationContent
{
    // set up webview
    
    CGRect webViewFrame = CGRectMake(10, 10, self.tableView.frame.size.width - 40, 1);
    if (!_webView) {
        _webView = [[UIWebView alloc] initWithFrame:webViewFrame];
        _webView.delegate = self;
    } else {
        _webView.frame = webViewFrame;
    }
    
    NSString *info = nil;
    if ([self.annotation isKindOfClass:[KGOPlacemark class]]) {
        info = [(KGOPlacemark *)self.annotation info];
        
    } else if ([self.annotation isKindOfClass:[ScheduleEventWrapper class]]
               && [(ScheduleEventWrapper *)self.annotation placemarkID]
               ) {
        info = [NSString stringWithFormat:@"Building Number: %@", [(ScheduleEventWrapper *)self.annotation placemarkID]];
    }
    
    NSDictionary *replacements = [NSDictionary dictionaryWithObjectsAndKeys:info, @"BODY", nil];
    NSString *string = [_htmlTemplate stringWithReplacements:replacements];
    [_webView loadHTMLString:string baseURL:nil];
    
    // set up photo
    
    UIImage *image = nil;
    NSString *imageURL = nil;
    if ([self.annotation isKindOfClass:[KGOPlacemark class]]) {
        image = [UIImage imageWithData:[(KGOPlacemark *)self.annotation photo]];
        imageURL = [(KGOPlacemark *)self.annotation photoURL];
    } else if ([self.annotation isKindOfClass:[ScheduleEventWrapper class]]) {
        
    }
    
    if (image || imageURL) {
        if (!_thumbView) {
            _thumbView = [[MITThumbnailView alloc] initWithFrame:CGRectMake(10, 10, 1, 1)];
            _thumbView.delegate = self;
        }
        
        if (image) {
            CGFloat maxWidth = self.tableView.frame.size.width - 40;
            CGFloat ratio = maxWidth / image.size.width;
            CGRect frame = _thumbView.frame;
            frame.size = CGSizeMake(floor(ratio * image.size.width), floor(ratio * image.size.height));
            _thumbView.frame = frame;
            _thumbView.imageData = UIImagePNGRepresentation(image);
            [_thumbView displayImage];
            
        } else {
            _thumbView.imageURL = imageURL;
            _thumbView.imageData = nil;
            [_thumbView loadImage];
        }
        
    } else if (_thumbView) {
        [_thumbView removeFromSuperview];
        [_thumbView release];
        _thumbView = nil;
    }
}

- (void)pager:(KGODetailPager*)pager showContentForPage:(id<KGOSearchResult>)content {
    if ([content isKindOfClass:[KGOPlacemark class]]) {
        self.annotation = (id<MKAnnotation, KGOSearchResult>)content;
        _headerView.detailItem = self.annotation;
        [self loadAnnotationContent];
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
    
    if ([self.annotation isKindOfClass:[KGOPlacemark class]]) {
        self.title = @"Building Detail";
    } else if ([self.annotation isKindOfClass:[ScheduleEventWrapper class]]) {
        self.title = @"Event Location";
    }
    
    if (self.pager) {
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:self.pager] autorelease];
    }
    
    if (!_headerView) {
        _headerView = [[ReunionDetailPageHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 1)];
        _headerView.delegate = self;
        _headerView.showsBookmarkButton = YES;
    }
    _headerView.detailItem = self.annotation;
    self.tableView.tableHeaderView = _headerView;
    
    if (!_htmlTemplate) {
        _htmlTemplate = [[KGOHTMLTemplate templateWithPathName:@"modules/map/detail.html"] retain];
    }
    [self loadAnnotationContent];
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
        height = _webView.frame.size.height + 20;
        if (_thumbView) {
            height += _thumbView.frame.size.height + 10;
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
            if (![_webView isDescendantOfView:cell.contentView]) {
                [cell.contentView addSubview:_webView];
            }
            
            if (_thumbView) {
                if (![_thumbView isDescendantOfView:cell.contentView]) {
                    [cell.contentView addSubview:_thumbView];
                }
                
                CGFloat y = _thumbView.frame.origin.y + _thumbView.frame.size.height;
                if (y > 11) {
                    _webView.frame = CGRectMake(10, y + 10, _webView.frame.size.width, _webView.frame.size.height);
                }
            }
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
    CGSize size = [webView sizeThatFits:CGSizeMake(1, 1)];
    if (size.height != frame.size.height) {
        frame.size.height = size.height;
        webView.frame = frame;
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
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1]
                          withRowAnimation:UITableViewRowAnimationNone];
        }
        
    }
}

@end
