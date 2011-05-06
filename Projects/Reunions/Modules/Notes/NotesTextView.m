//
//  NotesTextView.m
//  Reunions
//
//  Created by Muhammad J Amjad on 4/15/11.
//  Copyright 2011 ModoLabs Inc. All rights reserved.
//

#import "NotesTextView.h"
#import "KGOTheme.h"
#import "CoreDataManager.h"
#import "MITMailComposeController.h"


#define MIN_HEIGHT = 250
#define MAX_HEIGHT = 350;


@implementation NotesTextView
@synthesize delegate;

- (id)initWithFrame:(CGRect)frame titleText:(NSString * ) titleText detailText: (NSString *) dateText noteText: (NSString *) noteText note:(Note *) savedNote firstResponder:(BOOL) firstResponder dateFont:(UIFont *) font
{
    if (frame.size.height < 500)
        frame.size.height = 500;
    
    else if (frame.size.height > 800)
        frame.size.height = 800;
    
    self = [super initWithFrame:frame];
    if (self) {
        UIImage *shareButtonImage = [UIImage imageWithPathName:@"common/share.png"];
        UIImage *deleteButtonImage = [UIImage imageWithPathName:@"common/subheadbar_button.png"];
        
        CGFloat buttonX = self.frame.size.width - deleteButtonImage.size.width - shareButtonImage.size.width - 20;
        CGFloat buttonY = 10;
        
        UIFont *fontTitle = [UIFont fontWithName:@"Georgia" size:18];//[[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyContentTitle];
        CGSize titleSize = [titleText sizeWithFont:fontTitle];
        UILabel * titleTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, buttonX - 20, titleSize.height + 5)];
        titleTextLabel.text = titleText;
        titleTextLabel.font = fontTitle;
        titleTextLabel.numberOfLines = 1;
        titleTextLabel.lineBreakMode = UILineBreakModeTailTruncation;
        titleTextLabel.textColor = [UIColor blackColor];
        titleTextLabel.backgroundColor = [UIColor clearColor];
        
        CGSize detailSize;
        
        UIFont *fontDetail = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListSubtitle];
        
        if (nil != font){
            if (([dateText sizeWithFont:font]).height > 0)
                fontDetail = font;
           
        }
         detailSize = [dateText sizeWithFont:fontDetail];
        UILabel * detailTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, titleTextLabel.frame.size.height + 8, buttonX - 20, detailSize.height + 5)];
        detailTextLabel.text = dateText;
        detailTextLabel.font = fontDetail;
        detailTextLabel.numberOfLines = 1;
        detailTextLabel.lineBreakMode = UILineBreakModeTailTruncation;
        detailTextLabel.textColor = [UIColor grayColor];
        detailTextLabel.backgroundColor = [UIColor clearColor];
        
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
        
        titleTextLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        detailTextLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        
        shareButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
        deleteButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
        self.autoresizesSubviews = YES;

        [self addSubview:titleTextLabel];
        [self addSubview:detailTextLabel];
        [self addSubview:shareButton];
        [self addSubview:deleteButton];

        UIImage * image = [UIImage imageWithPathName:@"modules/schedule/faketop-above-selection.png"];
        UIImageView * sectionDivider;
        if (image){
            sectionDivider = [[UIImageView alloc] initWithImage:[image stretchableImageWithLeftCapWidth:0 topCapHeight:0]];
            sectionDivider.frame = CGRectMake(15, 
                                              titleTextLabel.frame.size.height + detailTextLabel.frame.size.height + 10, 
                                              self.frame.size.width, 
                                              4);
            sectionDivider.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
            [self addSubview:sectionDivider];
        }
        
        
        
        if (nil == detailsView) {
            
            detailsView = [[UITextView alloc] initWithFrame:CGRectMake(10, 
                                                                       titleTextLabel.frame.size.height + detailTextLabel.frame.size.height + 10, 
                                                                       self.frame.size.width - 10, 
                                                                       self.frame.size.height - titleTextLabel.frame.size.height - detailTextLabel.frame.size.height - 25)];
            detailsView.delegate = self;
            detailsView.backgroundColor = [UIColor clearColor];
            detailsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            
            [self addSubview:detailsView];
            
            detailsView.font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyByline];
            detailsView.text = noteText;
            
            if (firstResponder == YES) {
                [detailsView becomeFirstResponder];
            }

        }
        
        self.backgroundColor = [UIColor clearColor];
        
        if (nil != note)
            [note release];
        
        note = [savedNote retain];
    }
    return self;
}

-(void) printButtonPressed: (id) sender {
    
    NSString * titleText = [Note noteTitleFromDetails:detailsView.text];
    
    if (nil != note.eventIdentifier)
        titleText = note.title;
    
    NSString * textToPrint = [NSString stringWithFormat:@"%@:\n\n%@", titleText, detailsView.text];
    
    [Note printContent:textToPrint jobTitle:titleText fromButton:printButton parentView:self delegate:self];
}

-(void) shareButtonPressed: (id) sender {
    
    NSString * emailSubject = note.title;
    
    if (nil == note.eventIdentifier)
        emailSubject = [NSString stringWithFormat:@"Note: %@",[Note noteTitleFromDetails:detailsView.text]];
    
    [self.delegate presentMailControllerWithEmail: nil
                                          subject: emailSubject
                                             body: detailsView.text
                                         delegate:self];
    
}

- (void) deleteButtonPressed: (id) sender {
    
    UIActionSheet * deleteActionSheet = [[UIActionSheet alloc] initWithTitle:@"Are you sure you want to delete the note?" 
                                                                    delegate:self 
                                                           cancelButtonTitle:nil
                                                      destructiveButtonTitle:@"Delete" 
                                                           otherButtonTitles:@"Cancel", nil];
    
    [deleteActionSheet showInView:self];
    [deleteActionSheet release];
}


- (void)dealloc
{
    [super dealloc];
}


-(void) saveNote {
    if (nil != note) {
        
        if (nil == note.eventIdentifier)
            note.title = [Note noteTitleFromDetails:detailsView.text];
        
        note.details = detailsView.text;
        
        [[CoreDataManager sharedManager] saveData];
    }
    
}
        

#pragma mark
#pragma mark UITextViewDelegate

- (void)textViewDidEndEditing:(UITextView *)textView {
    
    [self saveNote];
    
}

#pragma mark
#pragma mark MFMailComposeViewControllerDelegate

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    
    if ([self.delegate respondsToSelector:@selector(dismissModalViewControllerAnimated:andReload:)])
        [self.delegate dismissModalViewControllerAnimated:YES andReload:NO];
    
    else
        [self.delegate dismissModalViewControllerAnimated:YES];
}

#pragma mark
#pragma mark UIActionSheetDelegate
/*
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 0) {// destructive button pressed
        NSLog(@"delete button pressed from notes-listview");
    }
}
*/

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([title isEqualToString:@"Delete"]) {
        [self removeFromSuperview];
        [self.delegate deleteNoteAndReload:note];
    }
}

@end
