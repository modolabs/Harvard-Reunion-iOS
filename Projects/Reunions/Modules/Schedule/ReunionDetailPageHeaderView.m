#import "ReunionDetailPageHeaderView.h"
#import "UIKit+KGOAdditions.h"
#import "KGOSearchModel.h"
#import "ScheduleEventWrapper.h"

@implementation ReunionDetailPageHeaderView

#define LABEL_PADDING 10
#define MAX_TITLE_LINES 3
#define MAX_SUBTITLE_LINES 5

- (void)layoutSubviews
{
    CGRect oldFrame = self.frame;
    CGFloat titleHeight = 0;
    CGFloat subtitleHeight = 0;
    CGFloat buttonHeight = 0;
    
    if (_showsBookmarkButton) {
        [self layoutBookmarkButton];
        buttonHeight = _bookmarkButton.frame.size.height + LABEL_PADDING;
    }
    
    CGFloat labelWidth = self.bounds.size.width - LABEL_PADDING - _bookmarkButton.frame.size.width;
    
    if (_titleLabel) {
        CGSize constraintSize = CGSizeMake(labelWidth, _titleLabel.font.lineHeight * MAX_TITLE_LINES);
        CGSize textSize = [_titleLabel.text sizeWithFont:_titleLabel.font constrainedToSize:constraintSize];
        _titleLabel.frame = CGRectMake(LABEL_PADDING, LABEL_PADDING, labelWidth, textSize.height);
        
        if (![_titleLabel isDescendantOfView:self]) {
            [self addSubview:_titleLabel];
        }
        titleHeight = _titleLabel.frame.size.height + LABEL_PADDING;
    }
    
    if (_subtitleLabel) {
        CGSize constraintSize = CGSizeMake(labelWidth, _subtitleLabel.font.lineHeight * MAX_SUBTITLE_LINES);
        CGSize textSize = [_subtitleLabel.text sizeWithFont:_subtitleLabel.font constrainedToSize:constraintSize];
        CGFloat y = LABEL_PADDING;
        if (_titleLabel) {
            y += _titleLabel.frame.size.height + LABEL_PADDING;
        }
        _subtitleLabel.frame = CGRectMake(LABEL_PADDING, y, labelWidth, textSize.height);
        
        if (![_subtitleLabel isDescendantOfView:self]) {
            [self addSubview:_subtitleLabel];
        }
        subtitleHeight = _subtitleLabel.frame.size.height + LABEL_PADDING;
    }
    
    CGRect frame = self.frame;
    frame.size.height = fmaxf(titleHeight + subtitleHeight, buttonHeight) + LABEL_PADDING;
    self.frame = frame;
    
    if ((self.frame.size.width != oldFrame.size.width || self.frame.size.height != oldFrame.size.height)
        && [self.delegate respondsToSelector:@selector(headerViewFrameDidChange:)]
    ) {
        [self.delegate headerViewFrameDidChange:self];
    }
}

- (void)layoutBookmarkButton
{
    if (!_bookmarkButton) {
        UIImage *placeholder = [UIImage imageWithPathName:@"common/bookmark-ribbon-off.png"];
        CGFloat buttonX = self.bounds.size.width - LABEL_PADDING - placeholder.size.width;
        
        _bookmarkButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        _bookmarkButton.frame = CGRectMake(buttonX, 0, placeholder.size.width, placeholder.size.height);
        
        [_bookmarkButton addTarget:self action:@selector(toggleBookmark:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_bookmarkButton];
        
    }
    
    UIImage *buttonImage;
    if ([self.detailItem isBookmarked]
        || ([self.detailItem isKindOfClass:[ScheduleEventWrapper class]] && [(ScheduleEventWrapper *)self.detailItem isRegistered])
    ) {
        buttonImage = [UIImage imageWithPathName:@"common/bookmark-ribbon-on.png"];
    } else if ([self.detailItem isKindOfClass:[ScheduleEventWrapper class]]) {
        buttonImage = [UIImage imageWithPathName:@"common/bookmark-schedule-off.png"];
    } else {
        buttonImage = [UIImage imageWithPathName:@"common/bookmark-ribbon-off.png"];
    }
    [_bookmarkButton setImage:buttonImage forState:UIControlStateNormal];
}

- (void)hideBookmarkButton
{
    if (_bookmarkButton) {
        [_bookmarkButton removeFromSuperview];
        [_bookmarkButton release];
        _bookmarkButton = nil;
    }
}

- (void)toggleBookmark:(id)sender
{
    if ([self.detailItem isKindOfClass:[ScheduleEventWrapper class]]) {
        ScheduleEventWrapper *event = (ScheduleEventWrapper *)self.detailItem;
        if ([event isRegistered]) {
            UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:nil
                                                                 message:@"Events you have registered for cannot be removed from your schedule."
                                                                delegate:nil
                                                       cancelButtonTitle:@"OK"
                                                       otherButtonTitles:nil] autorelease];
            [alertView show];
            return;
        }
        
        if ([event registrationURL] && ![event isBookmarked]) {
            UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:nil
                                                                 message:@"Bookmarking this event will only add it to your personal schedule.  You will still need to register for it to attend."
                                                                delegate:self
                                                       cancelButtonTitle:@"OK"
                                                       otherButtonTitles:nil] autorelease];
            [alertView show];
            return;
        }
    }
    
    if ([self.detailItem isBookmarked]) {
        [self.detailItem removeBookmark];
    } else {
        [self.detailItem addBookmark];
    }
    
    [self layoutBookmarkButton];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (![self.detailItem isBookmarked]) {
        [self.detailItem addBookmark];
    }
    
    [self layoutBookmarkButton];
}

- (void)layoutShareButton
{
    // do nothing
}

- (void)hideShareButton
{
    // do nothing
}

@end
