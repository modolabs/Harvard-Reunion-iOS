//
//  NotesTextView.m
//  Reunions
//
//  Created by Muhammad J Amjad on 4/15/11.
//  Copyright 2011 ModoLabs Inc. All rights reserved.
//

#import "NotesTextView.h"
#import "UIKit+KGOAdditions.h"
#import "KGOTheme.h"


@implementation NotesTextView

- (id)initWithFrame:(CGRect)frame titleText:(NSString * ) titleText detailText: (NSString *) detailText
{
    if (frame.size.height < 500)
        frame.size.height = 500;
    
    else if (frame.size.height > 800)
        frame.size.height = 800;
    
    self = [super initWithFrame:frame];
    if (self) {
        UIFont *fontTitle = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyContentTitle];
        CGSize titleSize = [titleText sizeWithFont:fontTitle];
        UILabel * titleTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, self.frame.size.width - 130, titleSize.height + 5.0)];
        titleTextLabel.text = titleText;
        titleTextLabel.font = fontTitle;
        titleTextLabel.numberOfLines = 1;
        titleTextLabel.lineBreakMode = UILineBreakModeTailTruncation;
        titleTextLabel.textColor = [UIColor blackColor];
        titleTextLabel.backgroundColor = [UIColor clearColor];
        
        UIFont *fontDetail = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyContentSubtitle];
        CGSize detailSize = [detailText sizeWithFont:fontTitle];
        UILabel * detailTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, titleTextLabel.frame.size.height + 10, self.frame.size.width - 130, detailSize.height + 5.0)];
        detailTextLabel.text = detailText;
        detailTextLabel.font = fontDetail;
        detailTextLabel.numberOfLines = 1;
        detailTextLabel.lineBreakMode = UILineBreakModeTailTruncation;
        detailTextLabel.textColor = [UIColor blackColor];
        detailTextLabel.backgroundColor = [UIColor clearColor];
        
        UIImage *shareButtonImage = [UIImage imageWithPathName:@"common/share.png"];
        CGFloat buttonX = self.frame.size.width - 120;
        CGFloat buttonY = 5;
        
        UIButton * shareButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        shareButton.frame = CGRectMake(buttonX, buttonY, shareButtonImage.size.width, shareButtonImage.size.height);
        [shareButton setImage:shareButtonImage forState:UIControlStateNormal];
        [shareButton setImage:[UIImage imageWithPathName:@"common/share_pressed.png"] forState:UIControlStateHighlighted];

        [shareButton addTarget:self action:@selector(shareButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        
        
        UIImage *deleteButtonImage = [UIImage imageWithPathName:@"common/subheadbar_button.png"];
        buttonX += shareButtonImage.size.width + 5;
        
        UIButton * deleteButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        deleteButton.frame = CGRectMake(buttonX, buttonY, deleteButtonImage.size.width, deleteButtonImage.size.height);
        [deleteButton setImage:deleteButtonImage forState:UIControlStateNormal];
        [deleteButton setImage:[UIImage imageWithPathName:@"common/subheadbar_button.png"] forState:UIControlStateHighlighted];
        
        [deleteButton addTarget:self action:@selector(deleteButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
               
        [self addSubview:titleTextLabel];
        [self addSubview:detailTextLabel];
        [self addSubview:shareButton];
        [self addSubview:deleteButton];

        
        UIImage * image = [UIImage imageWithPathName:@"modules/schedule/faketop-above-selection.png"];
        UIImageView * sectionDivider;
        if (image){
            sectionDivider = [[UIImageView alloc] initWithImage:[image stretchableImageWithLeftCapWidth:0 topCapHeight:0]];
            sectionDivider.frame = CGRectMake(15, 
                                              titleTextLabel.frame.size.height + detailTextLabel.frame.size.height + 15, 
                                              self.frame.size.width, 
                                              4);
            
            [self addSubview:sectionDivider];
        }
        
        
        
        if (nil == detailsView) {
            
            detailsView = [[UITextView alloc] initWithFrame:CGRectMake(0, 
                                                                       titleTextLabel.frame.size.height + detailTextLabel.frame.size.height + 25, 
                                                                       self.frame.size.width, 
                                                                       self.frame.size.height - titleTextLabel.frame.size.height - detailTextLabel.frame.size.height - 25)];
            detailsView.backgroundColor = [UIColor clearColor];
            
            [self addSubview:detailsView];
            [detailsView becomeFirstResponder];
            detailsView.font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyByline];
        }
        
        self.backgroundColor = [UIColor clearColor];

    }
    return self;
}

-(void) shareButtonPressed: (id) sender {
    
}

- (void) deleteButtonPressed: (id) sender {
    
    UIActionSheet * deleteActionSheet = [[UIActionSheet alloc] initWithTitle:@"Are you sure you want to delete the note?" 
                                                                    delegate:self 
                                                           cancelButtonTitle:@"Cancel" 
                                                      destructiveButtonTitle:@"Delete" 
                                                           otherButtonTitles:nil];
    
    //deleteActionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    [deleteActionSheet showInView:self];
    [deleteActionSheet release];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)dealloc
{
    [super dealloc];
}


#pragma mark
#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 0) {// destructive button pressed
        NSLog(@"delete button");
    }
}

@end
