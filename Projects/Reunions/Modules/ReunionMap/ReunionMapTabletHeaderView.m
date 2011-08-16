
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import "ReunionMapTabletHeaderView.h"
#import "UIKit+KGOAdditions.h"
#import "KGOSidebarFrameViewController.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "ReunionMapDetailHeaderView.h"
#import "ScheduleEventWrapper.h"

#define CLOSE_BUTTON_WIDTH 60
// this is from KGOSidebarFrameViewController
#define DETAIL_VIEW_WIDTH 340

#define LABEL_PADDING_SMALL 2
#define LABEL_PADDING_LARGE 10
#define MAX_TITLE_LINES 3
#define MAX_SUBTITLE_LINES 5

@implementation ReunionMapTabletHeaderView

- (UIButton *)closeButton
{
    if (!_closeButton) {
        _closeButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        UIImage *image = [[UIImage imageWithPathName:@"common/light-button-background"] stretchableImageWithLeftCapWidth:5 topCapHeight:5];
        UIImage *pressedImage = [[UIImage imageWithPathName:@"common/light-button-background-pressed"] stretchableImageWithLeftCapWidth:5 topCapHeight:5];
        
        _closeButton.frame = CGRectMake(DETAIL_VIEW_WIDTH - CLOSE_BUTTON_WIDTH - LABEL_PADDING_LARGE,
                                        LABEL_PADDING_LARGE,
                                        CLOSE_BUTTON_WIDTH, 31);

        [_closeButton setBackgroundImage:image forState:UIControlStateNormal];
        [_closeButton setBackgroundImage:pressedImage forState:UIControlStateHighlighted];
        
        [_closeButton setTitle:@"Close" forState:UIControlStateNormal];
        [_closeButton setTitleColor:[UIColor colorWithWhite:0.2 alpha:1] forState:UIControlStateNormal];
        [_closeButton setTitleColor:[UIColor colorWithWhite:0.2 alpha:1] forState:UIControlStateHighlighted];
        _closeButton.titleLabel.font = [UIFont boldSystemFontOfSize:13];
        
        KGOSidebarFrameViewController *homescreen = (KGOSidebarFrameViewController *)[KGO_SHARED_APP_DELEGATE() homescreen];
        [_closeButton addTarget:homescreen action:@selector(hideDetailViewController) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

- (void)layoutSubviews
{
    if (_placeSubtitleLabel) {
        [_placeSubtitleLabel removeFromSuperview];
    }
    if (_placeTitleLabel) {
        [_placeTitleLabel removeFromSuperview];
    }
    
    if ([self.detailItem isKindOfClass:[ScheduleEventWrapper class]]) {
        CGRect oldFrame = self.frame;
        
        ScheduleEventWrapper *event = (ScheduleEventWrapper *)self.detailItem;
        
        CGFloat maxWidth = self.bounds.size.width - CLOSE_BUTTON_WIDTH - 3 * LABEL_PADDING_LARGE;
        CGFloat y = LABEL_PADDING_LARGE;
        
        if (_titleLabel) {
            CGSize constraintSize = CGSizeMake(maxWidth, _titleLabel.font.lineHeight * MAX_TITLE_LINES);
            CGSize textSize = [_titleLabel.text sizeWithFont:_titleLabel.font constrainedToSize:constraintSize];
            _titleLabel.frame = CGRectMake(LABEL_PADDING_LARGE, y, maxWidth, textSize.height);
            y += _titleLabel.frame.size.height;
        }
        
        if (_subtitleLabel) {
            y += LABEL_PADDING_SMALL;
            CGSize constraintSize = CGSizeMake(maxWidth, _subtitleLabel.font.lineHeight * MAX_SUBTITLE_LINES);
            CGSize textSize = [_subtitleLabel.text sizeWithFont:_subtitleLabel.font constrainedToSize:constraintSize];
            _subtitleLabel.frame = CGRectMake(LABEL_PADDING_LARGE, y, maxWidth, textSize.height);
            y += _subtitleLabel.frame.size.height;
        }
        
        if (![_closeButton isDescendantOfView:self]) {
            [self addSubview:self.closeButton];
        }
        
        y += LABEL_PADDING_LARGE;
        
        [self layoutBookmarkButton];
        
        CGRect bookmarkFrame = _bookmarkButton.frame;
        bookmarkFrame.origin.y = y;
        bookmarkFrame.origin.x = LABEL_PADDING_LARGE;
        _bookmarkButton.frame = bookmarkFrame;
        
        // two extra views for the location
        maxWidth = self.frame.size.width - _bookmarkButton.frame.size.width - 3 * LABEL_PADDING_LARGE;
        CGFloat x = _bookmarkButton.frame.size.width + 2 * LABEL_PADDING_LARGE;
        
        if (event.briefLocation) {
            if (!_placeTitleLabel) {
                _placeTitleLabel = [[UILabel alloc] init];
                _placeTitleLabel.backgroundColor = [UIColor clearColor];
                _placeTitleLabel.font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListTitle];
                _placeTitleLabel.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyContentTitle];
            }
            
            _placeTitleLabel.text = event.briefLocation;
            
            CGSize constraintSize = CGSizeMake(maxWidth, _subtitleLabel.font.lineHeight * MAX_SUBTITLE_LINES);
            CGSize textSize = [_placeTitleLabel.text sizeWithFont:_placeTitleLabel.font constrainedToSize:constraintSize];
            
            _placeTitleLabel.frame = CGRectMake(x, y, maxWidth, textSize.height);
            
            y += _placeTitleLabel.frame.size.height;
            
            [self addSubview:_placeTitleLabel];
        }
        
        if (event.location) {
            if (!_placeSubtitleLabel) {
                _placeSubtitleLabel = [[UILabel alloc] init];
                _placeSubtitleLabel.backgroundColor = [UIColor clearColor];
                _placeSubtitleLabel.font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyContentSubtitle];
                _placeSubtitleLabel.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyContentSubtitle];
            }
            
            y += LABEL_PADDING_SMALL;
            
            _placeSubtitleLabel.text = event.location;
            
            CGSize constraintSize = CGSizeMake(maxWidth, _subtitleLabel.font.lineHeight * MAX_SUBTITLE_LINES);
            CGSize textSize = [_placeSubtitleLabel.text sizeWithFont:_placeSubtitleLabel.font constrainedToSize:constraintSize];
            
            _placeSubtitleLabel.frame = CGRectMake(x, y, maxWidth, textSize.height);
            y += _placeSubtitleLabel.frame.size.height;
            
            [self addSubview:_placeSubtitleLabel];
        }
        
        y = fmaxf(y, _bookmarkButton.frame.origin.y + _bookmarkButton.frame.size.height);
        
        CGRect frame = self.frame;
        frame.size.height = y + LABEL_PADDING_LARGE;
        self.frame = frame;
        
        if ((self.frame.size.width != oldFrame.size.width || self.frame.size.height != oldFrame.size.height)
            && [self.delegate respondsToSelector:@selector(headerViewFrameDidChange:)]
        ) {
            [self.delegate headerViewFrameDidChange:self];
        }
        
    } else {
        CGRect oldFrame = self.frame;
        
        CGFloat maxWidth = self.bounds.size.width - CLOSE_BUTTON_WIDTH - 3 * LABEL_PADDING_LARGE;
        CGFloat y = LABEL_PADDING_LARGE;
        
        if (_titleLabel) {
            CGSize constraintSize = CGSizeMake(maxWidth, _titleLabel.font.lineHeight * MAX_TITLE_LINES);
            CGSize textSize = [_titleLabel.text sizeWithFont:_titleLabel.font constrainedToSize:constraintSize];
            _titleLabel.frame = CGRectMake(LABEL_PADDING_LARGE, y, maxWidth, textSize.height);
            y += fmaxf(_titleLabel.frame.size.height, _bookmarkButton.frame.size.height) + LABEL_PADDING_LARGE;
        }
        
        [self layoutBookmarkButton];
        
        CGRect bookmarkFrame = _bookmarkButton.frame;
        bookmarkFrame.origin.y = y;
        bookmarkFrame.origin.x = LABEL_PADDING_LARGE;
        _bookmarkButton.frame = bookmarkFrame;
        
        if (_subtitleLabel) {
            maxWidth = self.frame.size.width - _bookmarkButton.frame.size.width - 3 * LABEL_PADDING_LARGE;
            CGFloat x = _bookmarkButton.frame.size.width + 2 * LABEL_PADDING_LARGE;
            CGSize constraintSize = CGSizeMake(maxWidth, _subtitleLabel.font.lineHeight * MAX_SUBTITLE_LINES);
            CGSize textSize = [_subtitleLabel.text sizeWithFont:_subtitleLabel.font constrainedToSize:constraintSize];
            _subtitleLabel.frame = CGRectMake(x, y, maxWidth, textSize.height);
            y += _subtitleLabel.frame.size.height + LABEL_PADDING_LARGE;
        }
        
        y = fmaxf(y, _bookmarkButton.frame.origin.y + _bookmarkButton.frame.size.height);
        
        CGRect frame = self.frame;
        frame.size.height = y + LABEL_PADDING_LARGE;
        self.frame = frame;
        
        if ((self.frame.size.width != oldFrame.size.width || self.frame.size.height != oldFrame.size.height)
            && [self.delegate respondsToSelector:@selector(headerViewFrameDidChange:)]
        ) {
            [self.delegate headerViewFrameDidChange:self];
        }
    }
}



- (void)dealloc
{
    [super dealloc];
}

@end
