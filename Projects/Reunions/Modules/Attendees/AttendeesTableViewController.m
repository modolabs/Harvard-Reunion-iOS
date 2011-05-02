#import "AttendeesTableViewController.h"
#import "KGOTheme.h"
#import "KGORequestManager.h"
#import <QuartzCore/QuartzCore.h>
#import "KGOAppDelegate+ModuleAdditions.h"
#import "UIKit+KGOAdditions.h"
#import "Foundation+KGOAdditions.h"

NSString * const AllReunionAttendeesPrefKey = @"AllAttendees";

@implementation AttendeesTableViewController

@synthesize eventTitle, request, tableView = _tableView;

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

- (NSArray *)attendees
{
    return _attendees;
}

- (void)setAttendees:(NSArray *)attendees
{
    [_attendees release];
    _attendees = [attendees retain];
    
    if (_attendees.count) {
        NSMutableArray *titles = [NSMutableArray array];
        [_sections release];
        _sections = [[NSMutableDictionary alloc] init];
        
        for (NSDictionary *attendeeDict in self.attendees) {
            NSString *name = [attendeeDict objectForKey:@"display_name"];
            if (name.length) {
                NSString *firstLetter = [[name substringWithRange:NSMakeRange(0, 1)] capitalizedString];
                NSMutableArray *names = [_sections objectForKey:firstLetter];
                if (!names) {
                    names = [NSMutableArray array];
                    [_sections setObject:names forKey:firstLetter];
                    [titles addObject:firstLetter];
                }
                [names addObject:name];
            }
        }
        
        [_sectionTitles release];
        _sectionTitles = [[titles sortedArrayUsingSelector:@selector(compare:)] copy];
        
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];

    self.title = @"Attendees";
    
    NSString *listTitle = nil;

    NSDictionary *userDict = [[[KGORequestManager sharedManager] sessionInfo] dictionaryForKey:@"user"];
    NSString *username = [userDict stringForKey:@"name" nilIfEmpty:YES];
    if (!username) {
        listTitle = @"In order to see the list of attendees you must sign in";
    } else {
        listTitle = self.eventTitle;
    }

    UIFont *font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyContentTitle];
    CGFloat viewHeight = font.lineHeight + 24;

    UILabel *label = [UILabel multilineLabelWithText:listTitle font:font width:self.view.bounds.size.width - 20];
    label.frame = CGRectMake(10, 17, label.frame.size.width, label.frame.size.height);
    
    label.layer.shadowColor = [[UIColor blackColor] CGColor];
    label.layer.shadowOffset = CGSizeMake(0, 1);
    label.layer.shadowOpacity = 0.75;
    label.layer.shadowRadius = 1;
    
    CGRect titleFrame;
    if ([KGO_SHARED_APP_DELEGATE() navigationStyle] == KGONavigationStyleTabletSidebar) {
        label.textColor = [UIColor whiteColor];
        titleFrame = CGRectMake(0.0, 50, self.view.bounds.size.width, viewHeight);
        viewHeight += 50;
    } else {
        label.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyContentTitle];
        titleFrame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, viewHeight);
    }
    UIView *labelContainer = [[[UIView alloc] initWithFrame:titleFrame] autorelease];
    labelContainer.backgroundColor = [[KGOTheme sharedTheme] backgroundColorForApplication];
    [labelContainer addSubview:label];
    [self.view addSubview:labelContainer];
    
    if (username) {
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
        
        CGRect frame = CGRectMake(0, viewHeight, self.view.frame.size.width, self.view.frame.size.height - viewHeight);
        self.tableView = [[[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain] autorelease];
        self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        self.tableView.separatorColor = [UIColor whiteColor];
        self.tableView.rowHeight -= 10;
        
        [self.view addSubview:self.tableView];
        
    } else {
        UIButton *signoutButton = [UIButton buttonWithType:UIButtonTypeCustom];
        signoutButton.frame = CGRectMake(10, viewHeight + 10, 100, 31);
        [signoutButton setTitle:@"Sign in" forState:UIControlStateNormal];
        [signoutButton addTarget:[KGORequestManager sharedManager]
                          action:@selector(logoutKurogoServer)
                forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:signoutButton];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
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

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return _sectionTitles;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return index;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[_sections objectForKey:[_sectionTitles objectAtIndex:section]] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSArray *names = [_sections objectForKey:[_sectionTitles objectAtIndex:indexPath.section]];
    NSString *name = [names objectAtIndex:indexPath.row];
    cell.textLabel.text = name;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

@end
