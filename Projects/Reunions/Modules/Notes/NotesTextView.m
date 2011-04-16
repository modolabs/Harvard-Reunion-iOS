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
        UILabel * titleTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, self.frame.size.width - 10, titleSize.height + 5.0)];
        titleTextLabel.text = titleText;
        titleTextLabel.font = fontTitle;
        titleTextLabel.textColor = [UIColor blackColor];
        titleTextLabel.backgroundColor = [UIColor clearColor];
        
        UIFont *fontDetail = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyContentSubtitle];
        CGSize detailSize = [detailText sizeWithFont:fontTitle];
        UILabel * detailTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, titleTextLabel.frame.size.height + 10, self.frame.size.width - 10, detailSize.height + 5.0)];
        detailTextLabel.text = detailText;
        detailTextLabel.font = fontDetail;
        detailTextLabel.textColor = [UIColor blackColor];
        detailTextLabel.backgroundColor = [UIColor clearColor];
        
        [self addSubview:titleTextLabel];
        [self addSubview:detailTextLabel];
        
        UIImage * image = [UIImage imageWithPathName:@"modules/schedule/faketop-above-selection.png"];
        UIImageView * sectionDivider;
        if (image){
            sectionDivider = [[UIImageView alloc] initWithImage:[image stretchableImageWithLeftCapWidth:0 topCapHeight:0]];
            sectionDivider.frame = CGRectMake(15, 
                                              titleTextLabel.frame.size.height + detailTextLabel.frame.size.height + 15, 
                                              self.frame.size.width - 25, 
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

@end
