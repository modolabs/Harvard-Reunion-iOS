#import "AttendeesTableViewController.h"
#import "KGOTheme.h"
#import "KGORequestManager.h"

NSString * const AllReunionAttendeesPrefKey = @"AllAttendees";

@implementation AttendeesTableViewController

@synthesize attendees, eventTitle, request;

- (void)dealloc
{
    self.attendees = nil;
    self.eventTitle = nil;
    [self.request cancel];
    self.request = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Attendees";
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor clearColor];
    
    if (!self.attendees) {
        self.attendees = [[NSUserDefaults standardUserDefaults] objectForKey:AllReunionAttendeesPrefKey];
    }
    
    if (!self.attendees) {
        self.request = [[KGORequestManager sharedManager] requestWithDelegate:self module:@"attendees" path:@"all" params:nil];
        self.request.expectedResponseType = [NSArray class];
        if (self.request) {
            [self.request connect];
        }
    }
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

#pragma mark - KGORequestDelegate

- (void)requestWillTerminate:(KGORequest *)request
{
    self.request = nil;
}

- (void)request:(KGORequest *)request didReceiveResult:(id)result
{
    self.request = nil;
    self.attendees = result;
    
    [[NSUserDefaults standardUserDefaults] setObject:self.attendees forKey:AllReunionAttendeesPrefKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

#define GROUPED_SECTION_HEADER_VPADDING 24

// from KGOTableController.  we won't subclass KGOTableViewController because of very long lists
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (self.eventTitle) {
        UIFont *font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertySectionHeaderGrouped];
        CGFloat hPadding = 20.0f;
        CGFloat viewHeight = font.pointSize + GROUPED_SECTION_HEADER_VPADDING;
        
        CGSize size = [self.eventTitle sizeWithFont:font];
        UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(hPadding, floor((viewHeight - size.height) / 2), tableView.bounds.size.width - hPadding * 2, size.height)] autorelease];
        
        label.text = self.eventTitle;
        label.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertySectionHeaderGrouped];
        label.font = font;
        label.backgroundColor = [UIColor clearColor];
        
        UIView *labelContainer = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, tableView.bounds.size.width, viewHeight)] autorelease];
        labelContainer.backgroundColor =  [UIColor clearColor];
        [labelContainer addSubview:label];	
        
        return labelContainer;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (self.eventTitle) {
        return [[[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertySectionHeaderGrouped] lineHeight] + GROUPED_SECTION_HEADER_VPADDING;
    }
    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.attendees.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSDictionary *attendeeDict = [self.attendees objectAtIndex:indexPath.row];
    cell.textLabel.text = [attendeeDict objectForKey:@"display_name"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

@end
