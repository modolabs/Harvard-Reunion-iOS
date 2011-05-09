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
#import "MITMailComposeController.h"


@implementation NotesTableViewController

- (void) reloadNotes {
    [notesArray release];
    notesArray = [[[CoreDataManager sharedManager] objectsForEntity:NotesEntityName matchingPredicate:nil] retain];
    
    [selectedRowIndexPath release];
    selectedRowIndexPath = [[NSIndexPath indexPathForRow:notesArray.count -1 inSection:0] retain];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];

    if (self) {
        NSString * newNoteText = NSLocalizedString(@"New Note", nil);
        NSString * emailAllText = NSLocalizedString(@"Email All Notes", nil);
        //NSString * printAllText = NSLocalizedString(@"Print All Notes", nil);
        
        UIButton * newNoteButton = [self customButtonWithText:newNoteText xOffset:0 yOffset:5];
        UIButton * emailAllButton = [self customButtonWithText:emailAllText xOffset:newNoteButton.frame.size.width + 15 yOffset: 5];
        //printAllButton = [self customButtonWithText:printAllText 
        //                                               xOffset:newNoteButton.frame.size.width + emailAllButton.frame.size.width + 30 
        //                                               yOffset: 5];
        
        [newNoteButton addTarget:self action:@selector(newNoteButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [emailAllButton addTarget:self action:@selector(emailAllButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        //[printAllButton addTarget:self action:@selector(printAllButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.view addSubview:newNoteButton];
        [self.view addSubview:emailAllButton];
        
        [self.tableView removeFromSuperview];
        
        self.view.backgroundColor = [UIColor clearColor];
        CGRect frame = self.view.bounds;
        frame.origin.y += 44;
        frame.size.height -= 44;
        self.tableView = [self addTableViewWithFrame:frame style:style];
        
        self.tableView.backgroundColor = [UIColor clearColor];
        self.tableView.backgroundView = nil;
        self.tableView.separatorColor = [UIColor clearColor];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
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
/*
- (void) printAllButtonPressed: (id) sender {
    [self saveNotesState];
    [self reloadNotes];
    
    NSString * notesBody = @"";
    
    for(Note * noteItem in notesArray) {
        
        NSString * noteText = [NSString stringWithFormat:@"<b>%@</b><i>(%@)</i><b>:</b> <br> %@<br><br>", noteItem.title, [Note dateToDisplay:noteItem.date], noteItem.details];
        notesBody = [notesBody stringByAppendingString:noteText];
    }
    
    [Note printContent:notesBody jobTitle:@"Harvard Reunion: All notes" fromButton:printAllButton parentView:self.view delegate:self];
}
*/
- (void) emailAllButtonPressed: (id) sender {
    
    [self saveNotesState];
    [self reloadNotes];
    
    NSString * emailSubject = @"Harvard Reunion Notes";
    NSString * emailBody = @"";
    
    for(Note * noteItem in notesArray) {
        
        NSString * noteText = [NSString stringWithFormat:@"<b>%@</b><i>(%@)</i><b>:</b> <br> %@<br><br>", noteItem.title, [Note dateToDisplay:noteItem.date], noteItem.details];
        emailBody = [emailBody stringByAppendingString:noteText];
    }
    
    [self presentMailControllerWithEmail:nil subject:emailSubject body:emailBody delegate:self isHTML:YES];
}

- (void)newNoteButtonPressed:(id)sender {
    
    NSDate * noteDate = [NSDate date];
    [tempVC release];
    tempVC = [[NewNoteViewController alloc] initWithTitleText:@"<Empty Note>" 
                                                         date: noteDate               
                                                  andDateText:[Note dateToDisplay:noteDate]
                                                      eventId:nil
                                                    viewWidth:NEWNOTE_WIDTH 
                                                   viewHeight:NEWNOTE_HEIGHT];
    tempVC.viewControllerBackground = self;
                                       
    UINavigationController *navC = [[[UINavigationController alloc] initWithRootViewController:tempVC] autorelease];
    
    UIBarButtonItem *item = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                           target:self
                                                                           action:@selector(saveAndDismiss)] autorelease];
    tempVC.navigationItem.rightBarButtonItem = item;
    
    item = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                           target:self
                                                                           action:@selector(deleteNoteWithoutSaving)] autorelease];
    tempVC.navigationItem.leftBarButtonItem = item;
 
    navC.modalPresentationStyle =  UIModalPresentationFormSheet;
    navC.navigationBar.barStyle = UIBarStyleBlack;
    [self presentModalViewController:navC animated:YES];
    navC.view.userInteractionEnabled = YES;

    CGRect frame = navC.view.superview.frame;
    frame.size.width = NEWNOTE_WIDTH;
    navC.view.superview.frame = frame;
    //navC.view.superview.frame = CGRectMake(NEWNOTE_XOFFSET, NEWNOTE_YOFFSET, NEWNOTE_WIDTH, NEWNOTE_HEIGHT);//it's important to do this after presentModalViewController
}

-(void) saveNotesState {
    
    if ((nil != notesTextView) && ([notesArray count] > 0)){
        
        [notesTextView saveNote];
    }
    
    if (nil != tempVC) {
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"title = %@ AND date = %@", tempVC.titleText, tempVC.date];
        Note *note = [[[CoreDataManager sharedManager] objectsForEntity:NotesEntityName matchingPredicate:pred] lastObject];
        
        if (nil == note) {
            note = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:NotesEntityName];
        }
        
        note.title = [Note noteTitleFromDetails:tempVC.textViewString];
        note.date = tempVC.date;
        note.details = tempVC.textViewString;
        
        if (nil != tempVC.eventIdentifier)
            note.eventIdentifier = tempVC.eventIdentifier;
        
        [[CoreDataManager sharedManager] saveData];
    }
}

- (void)saveAndDismiss
{
    [self saveNotesState];
    [self reloadNotes];
    
    [selectedRowIndexPath release];
    selectedRowIndexPath = [[NSIndexPath indexPathForRow:notesArray.count -1 inSection:0] retain];

    [selectedNote release];
    selectedNote = [[notesArray objectAtIndex:notesArray.count -1] retain];
    
    [self.tableView reloadData];
    
    [tempVC release];
    tempVC = nil;
    
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark
#pragma mark MFMailComposeViewControllerDelegate

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    
    [self dismissModalViewControllerAnimated:YES];
}


#pragma mark
#pragma mark NotesModalViewDelegate 

-(void) deleteNoteWithoutSaving {
    
    [self dismissModalViewControllerAnimated:YES];
}

- (void)dealloc
{
    [tempVC release];
    [notesArray release];
    [selectedRowIndexPath release];
    [notesTextView release];
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
    [self reloadNotes];
    selectedNote = nil;
    selectedRowIndexPath = nil;
    
    if (notesArray.count >= 1) {
        selectedRowIndexPath = [[NSIndexPath indexPathForRow:notesArray.count -1 inSection:0] retain];
        selectedNote = [[notesArray objectAtIndex:notesArray.count -1] retain];
    }
    
    firstView = YES;
    [self.tableView reloadData];
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
    
    if (nil != selectedRowIndexPath)
        [self.tableView scrollToRowAtIndexPath:selectedRowIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    
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
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    || (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark
#pragma mark NotesTextViewDelegate

- (void)deleteNoteAndReload:(Note*)note{
    [[CoreDataManager sharedManager] deleteObject:note];
     [[CoreDataManager sharedManager] saveData];
    
    [self reloadNotes];
    [self.tableView reloadData];
    
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    int rows = 0;
    
    if (nil != notesArray)
        rows = notesArray.count;
    
    return rows;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (KGOTableCellStyle)tableView:(UITableView *)tableView styleForCellAtIndexPath:(NSIndexPath *)indexPath {

    return KGOTableCellStyleSubtitle;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Note * note = [notesArray objectAtIndex:indexPath.row];
    
    NSString * noteTitle = note.title;
    NSString * noteText = note.details;
    
    if ((selectedRowIndexPath != nil) && (selectedRowIndexPath == indexPath)) {
        static NSString *CellIdentifier = @"CellNotesSelected";
        
        NotesUnselectedTableViewCell *cell = (NotesUnselectedTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell == nil) {
            cell = [[[NotesUnselectedTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
        }
        
        cell.tableView = self.tableView;
        cell.notesCellType = NotesCellSelected;
        
        [notesTextView release];
        notesTextView = [[NotesTextView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - 8, 500) 
                                                    titleText:noteTitle
                                                   detailText:[Note dateToDisplay:note.date]
                                                     noteText:noteText
                                                         note:note
                                               firstResponder:!firstView
                                                     dateFont:cell.detailTextLabel.font];
        notesTextView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        notesTextView.autoresizesSubviews = YES;
        
        notesTextView.delegate = self;
        cell.detailsView = notesTextView;
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        
        return cell;
        
    }
    else{
        static NSString *CellIdentifier = @"CellNotes";
        
        NotesUnselectedTableViewCell *cell = (NotesUnselectedTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[NotesUnselectedTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
        }
        
        cell.tableView = self.tableView;
        cell.notesCellType = NotesCellTypeOther;
        cell.textLabel.font = [UIFont fontWithName:@"Georgia" size:18];
        cell.textLabel.text = noteTitle;
        cell.detailTextLabel.text = [Note dateToDisplay:note.date];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        
        
        return cell;
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    Note * note = [notesArray objectAtIndex:indexPath.row];
    
    NSString * noteTitle = note.title;
    NSString * noteText = note.details;
    
    if ((selectedRowIndexPath != nil) && (selectedRowIndexPath == indexPath)) {
        
        NotesTextView * temp = [[[NotesTextView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - 8, 500) 
                                                                    titleText:noteTitle
                                                                   detailText:[Note dateToDisplay:note.date]
                                                                     noteText:noteText
                                                                         note: note
                                                               firstResponder: !firstView
                                                                    dateFont:nil] autorelease];
        
        return temp.frame.size.height;
    }
    
    CGFloat height = [super tableView:tableView heightForRowAtIndexPath:indexPath];
    return height + 10;
}

-(void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ((selectedRowIndexPath != nil) && (selectedRowIndexPath == indexPath)){
        return;
    }
    
    firstView = NO;
    
    if (nil != notesArray) {
        selectedNote = [[notesArray objectAtIndex:indexPath.row] retain];
    }
    
    [selectedRowIndexPath release];
    selectedRowIndexPath = [indexPath retain];
    
    [self.tableView reloadData];
    
    [self.tableView scrollToRowAtIndexPath:selectedRowIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];

}



@end
