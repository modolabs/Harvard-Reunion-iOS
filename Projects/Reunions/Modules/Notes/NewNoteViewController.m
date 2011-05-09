//
//  NewNoteViewController.m
//  Reunions
//
//  Created by Muhammad J Amjad on 4/16/11.
//  Copyright 2011 ModoLabs Inc. All rights reserved.
//

#import "NewNoteViewController.h"
#import "UIKit+KGOAdditions.h"
#import "KGOTheme.h"
#import "Note.h"
#import "CoreDataManager.h"
#import "MITMailComposeController.h"


@implementation NewNoteViewController
@synthesize textViewString;
@synthesize titleText;
@synthesize dateText;
@synthesize date;
@synthesize eventIdentifier;
@synthesize width;
@synthesize height;
@synthesize viewControllerBackground;

-(id) initWithTitleText: (NSString *) title date: (NSDate *) dateCreated andDateText: (NSString *) dateString  eventId: (NSString *) eventId viewWidth: (double) viewWidth viewHeight: (double) viewHeight{
    
    self = [super init];
    
    if (self) {
        self.titleText = title;
        self.dateText = dateString;
        self.width = viewWidth;
        self.height = viewHeight;
        self.date = dateCreated;
        self.eventIdentifier = eventId;
    }
    
    return self;
}

- (void)dealloc
{
    [deleteButton release];
    [textView release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    [super loadView];
    
    UIImage *shareButtonImage = [UIImage imageWithPathName:@"modules/notes/share.png"];
    UIImage *deleteButtonImage = [UIImage imageWithPathName:@"modules/notes/delete.png"];
    
    CGFloat buttonX = self.width - deleteButtonImage.size.width - shareButtonImage.size.width - 20;
    CGFloat buttonY = 10;
    
    UIFont *fontTitle = [UIFont fontWithName:@"Georgia" size:18];;
    CGSize titleSize = [self.titleText sizeWithFont:fontTitle];
    UILabel * titleTextLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, 10,
                                                                          buttonX - 20,
                                                                          titleSize.height + 5)] autorelease];
    titleTextLabel.text = self.titleText;
    titleTextLabel.font = fontTitle;
    titleTextLabel.textColor = [UIColor blackColor];
    titleTextLabel.backgroundColor = [UIColor clearColor];
    
    UIFont *fontDetail = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListSubtitle];
    CGSize detailSize = [self.dateText sizeWithFont:fontTitle];
    UILabel * detailTextLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10,
                                                                           titleTextLabel.frame.size.height + 5,
                                                                           buttonX - 20,
                                                                           detailSize.height + 5)] autorelease];
    detailTextLabel.text = self.dateText;
    detailTextLabel.font = fontDetail;
    detailTextLabel.textColor = [UIColor grayColor];
    detailTextLabel.backgroundColor = [UIColor clearColor];
    
    UIButton * shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
    shareButton.frame = CGRectMake(buttonX, buttonY, shareButtonImage.size.width, shareButtonImage.size.height);
    [shareButton setImage:shareButtonImage forState:UIControlStateNormal];
    [shareButton setImage:[UIImage imageWithPathName:@"modules/notes/share_pressed.png"] forState:UIControlStateHighlighted];
    
    [shareButton addTarget:self action:@selector(shareButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    
    buttonX += shareButtonImage.size.width + 5;
    
    if (!deleteButton) {
        deleteButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        deleteButton.frame = CGRectMake(buttonX, buttonY, deleteButtonImage.size.width, deleteButtonImage.size.height);
        [deleteButton setImage:deleteButtonImage forState:UIControlStateNormal];
        [deleteButton setImage:[UIImage imageWithPathName:@"modules/notes/delete_pressed.png"] forState:UIControlStateHighlighted];
        
        [deleteButton addTarget:self action:@selector(deleteButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [self.view addSubview:titleTextLabel];
    [self.view addSubview:detailTextLabel];
    [self.view addSubview:shareButton];
    [self.view addSubview:deleteButton];
    
    
    
    if (nil == textView) {
        
        textView = [[UITextView alloc] initWithFrame:CGRectMake(10, 
                                                                titleTextLabel.frame.size.height + detailTextLabel.frame.size.height + 15, 
                                                                self.width - 10, 
                                                                self.height - titleTextLabel.frame.size.height - detailTextLabel.frame.size.height - 15)];
        textView.delegate = self;
        textView.backgroundColor = [UIColor clearColor];
        
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"title = %@", self.titleText];
        Note *note = [[[CoreDataManager sharedManager] objectsForEntity:NotesEntityName matchingPredicate:pred] lastObject];
        
        if (nil != note)
            if (nil != note.details)
                textView.text = note.details;
        
        [self.view addSubview:textView];
        [textView becomeFirstResponder];
        textView.font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyByline];
    }
    
     self.view.backgroundColor = [UIColor colorWithHexString:@"eee4b8"];
    
}

-(NSString *) textViewString {
    return textView.text;
}

-(void) shareButtonPressed: (id) sender {
    
    NSString * emailSubject = self.titleText;
    
    if (nil == self.eventIdentifier)
        emailSubject = [NSString stringWithFormat:@"Note: %@", [Note noteTitleFromDetails:self.textViewString]];
    
    [self presentMailControllerWithEmail: nil
                                          subject: emailSubject
                                             body: self.textViewString                                        
                                         delegate:self];
    
}

- (void) deleteButtonPressed: (id) sender {
    
    if (sender == deleteButton) {
        UIActionSheet * deleteActionSheet = [[UIActionSheet alloc] initWithTitle:@"Are you sure you want to delete the note?" 
                                                                        delegate:self 
                                                               cancelButtonTitle:nil
                                                          destructiveButtonTitle:@"Delete" 
                                                               otherButtonTitles:@"Cancel", nil];
        
        [deleteActionSheet showFromRect:deleteButton.frame inView:self.view animated:YES];
        [deleteActionSheet release];
    }
}



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
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

#pragma mark
#pragma mark MFMailComposeViewControllerDelegate

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark
#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([title isEqualToString:@"Delete"]) {
        [self.viewControllerBackground deleteNoteWithoutSaving];
    }
}

@end
