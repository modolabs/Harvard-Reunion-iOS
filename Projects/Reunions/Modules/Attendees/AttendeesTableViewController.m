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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
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

- (void)setupViews
{
    NSString *listTitle = nil;
    
    NSDictionary *userDict = [[[KGORequestManager sharedManager] sessionInfo] dictionaryForKey:@"user"];
    NSString *username = [userDict stringForKey:@"name" nilIfEmpty:YES];
    if (!username) {
        listTitle = @"In order to see the list of attendees, you must sign in.";
    } else {
        listTitle = self.eventTitle;
    }
    
    UIFont *font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyContentTitle];
    CGFloat viewHeight = font.lineHeight + 24;
    
    UILabel *label = nil;
    UIButton *signoutButton = (UIButton *)[self.view viewWithTag:100];
    
    if (!label) {
        font = [UIFont systemFontOfSize:17];
        label = [UILabel multilineLabelWithText:listTitle
                                           font:font
                                          width:self.view.frame.size.width - 100];
        label.tag = 10;
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        label.textAlignment = UITextAlignmentCenter;
        label.layer.shadowColor = [[UIColor blackColor] CGColor];
        label.layer.shadowOffset = CGSizeMake(0, 1);
        label.layer.shadowOpacity = 0.75;
        label.layer.shadowRadius = 1;
        label.textColor = [UIColor whiteColor];
    }

    
    
    if (username) {
        if (!self.attendees) {
            self.attendees = [[NSUserDefaults standardUserDefaults] objectForKey:AllReunionAttendeesPrefKey];
        }
        
        if (!self.attendees) {
            if (self.request) {
                [self.request cancel];
            }
            self.request = [[KGORequestManager sharedManager] requestWithDelegate:self module:@"attendees" path:@"all" params:nil];
            self.request.expectedResponseType = [NSArray class];
            if (self.request) {
                [self.request connect];
            }
        }
        
        CGFloat tableY = viewHeight;
        if ([KGO_SHARED_APP_DELEGATE() navigationStyle] == KGONavigationStyleTabletSidebar) {
            tableY = 44;
        }
        
        CGRect frame = CGRectMake(0, tableY, self.view.frame.size.width, self.view.frame.size.height - tableY);
        self.tableView = [[[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain] autorelease];
        self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        self.tableView.separatorColor = [UIColor whiteColor];
        self.tableView.rowHeight -= 10;
        
        [self.view addSubview:self.tableView];
        
        if (signoutButton) {
            [signoutButton removeFromSuperview];
        }
        
    } else {
        CGRect frameForLabel = CGRectZero;
        frameForLabel.size = CGSizeMake(self.view.frame.size.width - 100, 100);
        frameForLabel.origin.x = floor((self.view.frame.size.width - label.frame.size.width) / 2);
        frameForLabel.origin.y = 100;
        label.frame = frameForLabel;
        
        if (!signoutButton) {
            
            signoutButton = [UIButton buttonWithType:UIButtonTypeCustom];
            signoutButton.tag = 100;
            UIImage *image = [[UIImage imageWithPathName:@"common/red-button.png"]
                              stretchableImageWithLeftCapWidth:10 topCapHeight:10];
            signoutButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];
            [signoutButton addTarget:[KGORequestManager sharedManager]
                              action:@selector(logoutKurogoServer)
                    forControlEvents:UIControlEventTouchUpInside];
            signoutButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
            
            [signoutButton setBackgroundImage:image forState:UIControlStateNormal];
            [signoutButton setTitle:@"Sign in" forState:UIControlStateNormal];
        }
        
        CGRect frameForButton = CGRectZero;
        frameForButton.size = CGSizeMake(120, 40);
        frameForButton.origin.x = floor((self.view.frame.size.width - frameForButton.size.width) / 2);
        frameForButton.origin.y = label.frame.origin.y + label.frame.size.height + 20;
        signoutButton.frame = frameForButton;
        
        [self.view addSubview:label];
        [self.view addSubview:signoutButton];
        
        
        if (self.tableView) {
            [_tableView removeFromSuperview];
            self.tableView = nil;
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(setupViews)
                                                     name:KGODidLoginNotification object:nil];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    
    self.title = @"Attendees";
    
    [self setupViews];
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
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        || (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - KGORequestDelegate

- (void)requestWillTerminate:(KGORequest *)request
{
    self.request = nil;
}

- (void)request:(KGORequest *)request didReceiveResult:(id)result
{
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
