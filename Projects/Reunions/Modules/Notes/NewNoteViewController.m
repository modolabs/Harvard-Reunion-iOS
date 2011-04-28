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
    
    UIFont *fontTitle = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyContentTitle];
    CGSize titleSize = [self.titleText sizeWithFont:fontTitle];
    UILabel * titleTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 5,  self.width- 130, titleSize.height + 5.0)];
    titleTextLabel.text = self.titleText;
    titleTextLabel.font = fontTitle;
    titleTextLabel.textColor = [UIColor blackColor];
    titleTextLabel.backgroundColor = [UIColor clearColor];
    
    UIFont *fontDetail = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyContentSubtitle];
    CGSize detailSize = [self.dateText sizeWithFont:fontTitle];
    UILabel * detailTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, titleTextLabel.frame.size.height + 10, self.width - 130, detailSize.height + 5.0)];
    detailTextLabel.text = self.dateText;
    detailTextLabel.font = fontDetail;
    detailTextLabel.textColor = [UIColor blackColor];
    detailTextLabel.backgroundColor = [UIColor clearColor];
    
    UIImage *printButtonImage = [UIImage imageWithPathName:@"common/unread-message.png"];
    UIImage *shareButtonImage = [UIImage imageWithPathName:@"common/share.png"];
    UIImage *deleteButtonImage = [UIImage imageWithPathName:@"common/subheadbar_button.png"];
    
    CGFloat buttonX = self.width - deleteButtonImage.size.width - shareButtonImage.size.width - printButtonImage.size.width - 20;
    CGFloat buttonY = 5;
    
    printButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    printButton.frame = CGRectMake(buttonX, buttonY, printButtonImage.size.width, printButtonImage.size.height);
    [printButton setImage:printButtonImage forState:UIControlStateNormal];
    [printButton setImage:[UIImage imageWithPathName:@"common/unread-message.png"] forState:UIControlStateHighlighted];
    
    [printButton addTarget:self action:@selector(printButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    buttonX += printButtonImage.size.width + 5;
    
    UIButton * shareButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    shareButton.frame = CGRectMake(buttonX, buttonY, shareButtonImage.size.width, shareButtonImage.size.height);
    [shareButton setImage:shareButtonImage forState:UIControlStateNormal];
    [shareButton setImage:[UIImage imageWithPathName:@"common/share_pressed.png"] forState:UIControlStateHighlighted];
    
    [shareButton addTarget:self action:@selector(shareButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    
    buttonX += shareButtonImage.size.width + 5;
    
    UIButton * deleteButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    deleteButton.frame = CGRectMake(buttonX, buttonY, deleteButtonImage.size.width, deleteButtonImage.size.height);
    [deleteButton setImage:deleteButtonImage forState:UIControlStateNormal];
    [deleteButton setImage:[UIImage imageWithPathName:@"common/subheadbar_button.png"] forState:UIControlStateHighlighted];
    
    [deleteButton addTarget:self action:@selector(deleteButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    
    [self.view addSubview:titleTextLabel];
    [self.view addSubview:detailTextLabel];
    //[self.view addSubview:printButton];
    [self.view addSubview:shareButton];
    [self.view addSubview:deleteButton];
    
    UIImage * image = [UIImage imageWithPathName:@"modules/schedule/faketop-above-selection.png"];
    UIImageView * sectionDivider;
    if (image){
        sectionDivider = [[UIImageView alloc] initWithImage:[image stretchableImageWithLeftCapWidth:0 topCapHeight:0]];
        sectionDivider.frame = CGRectMake(15, 
                                          titleTextLabel.frame.size.height + detailTextLabel.frame.size.height + 15, 
                                          self.width, 
                                          4);
        
        [self.view addSubview:sectionDivider];
    }
    
    
    
    if (nil == textView) {
        
        textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 
                                                                titleTextLabel.frame.size.height + detailTextLabel.frame.size.height + 25, 
                                                                self.width, 
                                                                self.height - titleTextLabel.frame.size.height - detailTextLabel.frame.size.height - 25)];
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

-(void) printButtonPressed: (id) sender {
    
    NSString * noteTitle = self.titleText;
    
    if (nil == self.eventIdentifier)
        noteTitle = [NSString stringWithFormat:@"Note: %@", [Note noteTitleFromDetails:self.textViewString]];
    
    NSString * textToPrint = [NSString stringWithFormat:@"%@:\n\n%@", titleText, self.textViewString];
    
    [Note printContent:textToPrint jobTitle:noteTitle fromButton:printButton parentView:self.view delegate:self];
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
    
    UIActionSheet * deleteActionSheet = [[UIActionSheet alloc] initWithTitle:@"Are you sure you want to delete the note?" 
                                                                    delegate:self 
                                                           cancelButtonTitle:@"Cancel" 
                                                      destructiveButtonTitle:@"Delete" 
                                                           otherButtonTitles:nil];
    
    [deleteActionSheet showInView:self.view];
    [deleteActionSheet release];
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
    
    if (interfaceOrientation == UIInterfaceOrientationPortrait)
        return true;
    
    else if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft)
        return true;
    
    else if (interfaceOrientation == UIInterfaceOrientationLandscapeRight)
        return true;
    
    else
        return false;
    
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark
#pragma mark MFMailComposeViewControllerDelegate

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark
#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 0) {// destructive button pressed
        NSLog(@"note delete button pressed");
        
        if (nil != self.viewControllerBackground)
            [self.viewControllerBackground deleteNoteWithoutSaving];
    }
}

@end
