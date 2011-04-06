#import "ReunionMapDetailViewController.h"
#import "KGOPlacemark.h"
#import "KGOTheme.h"
#import "ThemeConstants.h"
#import "KGOHTMLTemplate.h"

@implementation ReunionMapDetailViewController

@synthesize placemark, pager;

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
        self.placemark = (KGOPlacemark *)content;
        
        _headerView.detailItem = self.placemark;
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
    //self.view.backgroundColor = [[KGOTheme sharedTheme] backgroundColorForApplication];
    
    if (self.pager) {
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:self.pager] autorelease];
    }
    
    if (!_headerView) {
        _headerView = [[ReunionDetailPageHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 1)];
        _headerView.delegate = self;
        _headerView.showsBookmarkButton = YES;
    }
    _headerView.detailItem = self.placemark;
    self.tableView.tableHeaderView = _headerView;
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
        return _webViewHeight + 20;
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
            cell.accessoryView = [[KGOTheme sharedTheme] accessoryViewForType:TableViewCellAccessoryExternal];
            break;
        case 1:
        {
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
            NSDictionary *replacements = [NSDictionary dictionaryWithObjectsAndKeys:self.placemark.info, @"BODY", nil];
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
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
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
        [self.tableView reloadData];
    }
}



@end
