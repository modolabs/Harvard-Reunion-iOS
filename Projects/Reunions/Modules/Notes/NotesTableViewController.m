//
//  NotesTableViewController.m
//  Reunions
//
//  Created by Muhammad J Amjad on 4/14/11.
//  Copyright 2011 ModoLabs Inc. All rights reserved.
//

#import "NotesTableViewController.h"
#import "UIKit+KGOAdditions.h"
#import "KGOTheme.h"
#import "KGOSidebarFrameViewController.h"
#import "NotesUnselectedTableViewCell.h"
#import "NotesTextView.h"
#import "NewNoteViewController.h"
#import "Note.h"
#import "CoreDataManager.h"

@implementation NotesTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    self.view.backgroundColor = [UIColor clearColor];
    //self.tableView.backgroundColor = [UIColor clearColor];
    if (self) {
        
        NSString * newNoteText = NSLocalizedString(@"New Note", nil);
        NSString * emailAllText = NSLocalizedString(@"Email All Notes", nil);
        
        UIButton * newNoteButton = [self customButtonWithText:newNoteText xOffset:0 yOffset:5];
        UIButton * emailAllButton = [self customButtonWithText:emailAllText xOffset:newNoteButton.frame.size.width + 15 yOffset: 5];
        
        [newNoteButton addTarget:self action:@selector(newNoteButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        //[aButton addTarget:self action:@selector(emailAllButtonPressed:) forControlEvents]:
        
        [self.view addSubview:newNoteButton];
        [self.view addSubview:emailAllButton];
        
        CGRect frame = self.view.frame;
        
        frame.origin.y += newNoteButton.frame.size.height + 15;
        frame.size.height -= newNoteButton.frame.size.height + 15;
        
        [self.tableView removeFromSuperview];
        self.tableView = [self addTableViewWithFrame:frame style:style];
        self.tableView.backgroundColor = [UIColor yellowColor];

        
    }
    return self;
}

-(UIButton *) customButtonWithText: (NSString *) title xOffset:(CGFloat)x yOffset:(CGFloat) y{
    
    NSString * aButtonText = title;
    UIButton *aButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [aButton setTitle:aButtonText forState:UIControlStateNormal];
    [aButton setTitleColor:[UIColor whiteColor]
                        forState:UIControlStateNormal];
    [aButton setTitleColor:[UIColor whiteColor]
                        forState:UIControlStateHighlighted];
    
    aButton.titleLabel.font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyScrollTabSelected];
    aButton.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 1.0, 0); // needed to center text vertically within button
    CGSize size = [aButton.titleLabel.text sizeWithFont:aButton.titleLabel.font];
    
    UIImage *stretchableButtonImage = [[UIImage imageWithPathName:@"common/secondary-toolbar-button.png"] stretchableImageWithLeftCapWidth:15 topCapHeight:0];
    UIImage *stretchableButtonImagePressed = [[UIImage imageWithPathName:@"common/secondary-toolbar-button-pressed.png"] stretchableImageWithLeftCapWidth:15 topCapHeight:0];
    
    [aButton setBackgroundImage:stretchableButtonImage forState:UIControlStateNormal];
    [aButton setBackgroundImage:stretchableButtonImagePressed forState:UIControlStateHighlighted];
    
    aButton.frame = CGRectMake(x, y, size.width +15, stretchableButtonImage.size.height);
    
    return aButton;
}

- (void)newNoteButtonPressed:(id)sender {
    
    double xOffset = 140;
    double yOffset = 75;
    double width = 600;
    double height = 675;
    
    if (nil != tempVC)
        [tempVC release];
    
    tempVC = [[[NewNoteViewController alloc] initWithTitleText:@"Temp New Note Title..." 
                                                                                  date:[NSDate date]                 
                                                                           andDateText:@"Created Thursday, Apr 2, 2011" 
                                                                             viewWidth:width 
                                                                            viewHeight:height] retain];
    tempVC.viewControllerBackground = self;
    //[tempVC becomeFirstResponder];
                                       
    UINavigationController *navC = [[[UINavigationController alloc] initWithRootViewController:tempVC] autorelease];
    
    UIBarButtonItem *item = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                           target:self
                                                                           action:@selector(dismissModalViewControllerAnimated:)] autorelease];
    
    tempVC.navigationItem.rightBarButtonItem = item;
 
    //categoryVC.navigationItem.rightBarButtonItem = item;
    navC.modalPresentationStyle =  UIModalPresentationFormSheet;
    [self presentModalViewController:navC animated:YES];
    navC.navigationBar.tintColor = [UIColor blackColor];
    navC.view.userInteractionEnabled = YES;

    
    //[navC.view becomeFirstResponder];
    navC.view.superview.frame = CGRectMake(xOffset, yOffset, width, height);//it's important to do this after presentModalViewController
    //navC.view.superview.center = self.view.center;

    
    
    //[self.view addSubview:modalView];

}

- (void) dismissModalViewControllerAnimated:(BOOL)animated {
    
    if (nil != tempVC) {
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"title = %@", tempVC.titleText];
        Note *note = nil; //[[[CoreDataManager sharedManager] objectsForEntity:NotesEntityName matchingPredicate:pred] lastObject];
        
        if (nil == note) {
            note = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:NotesEntityName];
        }
        
        note.title = tempVC.titleText;
        note.date = tempVC.date;
        note.details = tempVC.textViewString;
        
        if (nil != tempVC.eventIdentifier)
            note.eventIdentifier = tempVC.eventIdentifier;
        
        [[CoreDataManager sharedManager] saveData];
    }
    
    [super dismissModalViewControllerAnimated:YES];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
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

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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



#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 20;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (KGOTableCellStyle)tableView:(UITableView *)tableView styleForCellAtIndexPath:(NSIndexPath *)indexPath {
   // if (_currentCategories) {
     //   return KGOTableCellStyleDefault;
    //}
    return KGOTableCellStyleSubtitle;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ((selectedRowIndexPath != nil) && (selectedRowIndexPath == indexPath)) {
        static NSString *CellIdentifier = @"CellNotesSelected";
        
        NotesUnselectedTableViewCell *cell = (NotesUnselectedTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        cell = nil;
        if (cell == nil) {
            cell = [[[NotesUnselectedTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
        }
        
        cell.tableView = self.tableView;
        cell.notesCellType = NotesCellSelected;
        //cell.textLabel.text = @"Testing Notes blah blah blah";
        //cell.detailTextLabel.text = @"Date  xx-yy-zzzz";
        NotesTextView * notesTextView = [[NotesTextView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 500) 
                                                          titleText:@"Testing Notes blah blah blah"
                                                         detailText:@"Date  xx-yy-zzzz"];
        cell.detailsView = notesTextView;
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        
        return cell;
        
    }
    else{
        static NSString *CellIdentifier = @"CellNotes";
        
        NotesUnselectedTableViewCell *cell = (NotesUnselectedTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        cell = nil;
        if (cell == nil) {
            cell = [[[NotesUnselectedTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
        }
        
        cell.tableView = self.tableView;
        cell.notesCellType = NotesCellTypeOther;
        cell.textLabel.text = @"Testing Notes";
        cell.detailTextLabel.text = @"Date  xx-yy-zzzz";
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        
        
        return cell;
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    if ((selectedRowIndexPath != nil) && (selectedRowIndexPath == indexPath)) {
        
       NotesTextView * temp = [[NotesTextView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 500) 
                                                         titleText:@"Testing Notes blah blah blah"
                                                        detailText:@"Date  xx-yy-zzzz"];
        
        return temp.frame.size.height;
    }
    
    CGFloat height = [super tableView:tableView heightForRowAtIndexPath:indexPath];
    return height + 10;
}

-(void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ((selectedRowIndexPath != nil) && (selectedRowIndexPath == indexPath)){
        return;
    }
    
    NSIndexPath * prevSelectedRowIndexPath = selectedRowIndexPath;
    selectedRowIndexPath = indexPath;
    [self.tableView reloadData];
    
    [self.tableView scrollToRowAtIndexPath:selectedRowIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    
    /*if (nil != prevSelectedRowIndexPath)   {
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:prevSelectedRowIndexPath] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:selectedRowIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
    
    else
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:selectedRowIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    
    
     */
}
/*
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
        KGOEventWrapper *event = [eventsForSection objectAtIndex:indexPath.row];
        
        NSString *title = event.title;
        NSString *subtitle = [self.dataManager shortDateTimeStringFromDate:event.startDate];
        
        return [[^(UITableViewCell *cell) {
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.textLabel.text = title;
            cell.detailTextLabel.text = subtitle;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } copy] autorelease];
    }
    return nil;
}*/
/*
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_currentCategories) {
        KGOCalendar *calendar = [_currentCategories objectAtIndex:indexPath.row];
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:calendar, @"calendar", nil];
        [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameCategoryList forModuleTag:self.moduleTag params:params];
        
    } else if (_currentSections && _currentEventsBySection) {
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                _currentEventsBySection, @"eventsBySection",
                                _currentSections, @"sections",
                                indexPath, @"currentIndexPath",
                                nil];
        
        [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameDetail forModuleTag:self.moduleTag params:params];
    }
}*/



@end
