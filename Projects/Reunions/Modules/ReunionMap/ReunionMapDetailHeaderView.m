
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import "ReunionMapDetailHeaderView.h"
#import "KGOSearchModel.h"
#import "KGOPlacemark.h"
#import "ScheduleEventWrapper.h"
#import "KGOMapCategory.h"
#import "ReunionMapModule.h"
#import "UIKit+KGOAdditions.h"
#import "CoreDataManager.h"

#define LABEL_PADDING_SMALL 2
#define LABEL_PADDING_LARGE 10
#define MAX_TITLE_LINES 3
#define MAX_SUBTITLE_LINES 5

@implementation ReunionMapDetailHeaderView

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
        
        CGFloat maxWidth = self.bounds.size.width - 2 * LABEL_PADDING_LARGE;
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
        
        y += LABEL_PADDING_LARGE;
        
        [self layoutBookmarkButton];
        
        CGRect bookmarkFrame = _bookmarkButton.frame;
        bookmarkFrame.origin.y = y;
        _bookmarkButton.frame = bookmarkFrame;
        
        // two extra views for the location
        maxWidth = [self headerWidthWithButtons] - 2 * LABEL_PADDING_LARGE;
        
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
            
            _placeTitleLabel.frame = CGRectMake(LABEL_PADDING_LARGE, y, maxWidth, textSize.height);
            
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
            
            _placeSubtitleLabel.frame = CGRectMake(LABEL_PADDING_LARGE, y, maxWidth, textSize.height);
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
        [self setShowsBookmarkButton: YES];
        [super layoutSubviews];
    }
}

- (void)toggleBookmark:(id)sender
{
    if (_bookmarkedItem) {
        if ([_bookmarkedItem isBookmarked]) {
            [_bookmarkedItem removeBookmark];
        } else {
            [_bookmarkedItem addBookmark];
        }
        [self setupBookmarkButtonImages];
        
    } else {
        [super toggleBookmark:sender];
    }
}

- (void)setDetailItem:(id<KGOSearchResult>)detailItem
{
    [super setDetailItem:detailItem];
    
    [_bookmarkedItem release];
    _bookmarkedItem = nil;
    
    if ([self.detailItem isKindOfClass:[ScheduleEventWrapper class]]) {
        ScheduleEventWrapper *event = (ScheduleEventWrapper *)self.detailItem;

        NSArray *categoryPath = [NSArray arrayWithObject:EventMapCategoryName];
        KGOPlacemark *placemark = [KGOPlacemark placemarkWithID:event.identifier categoryPath:categoryPath];
        placemark.longitude = [NSNumber numberWithFloat:event.coordinate.longitude];
        placemark.latitude = [NSNumber numberWithFloat:event.coordinate.latitude];
        placemark.title = event.title;
        placemark.street = event.location;
        
        if (placemark) {
            [_bookmarkedItem release];
            _bookmarkedItem = [placemark retain];
        }
        
        NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
        [formatter setDateFormat:@"EEE, MMMM dd"];
        NSString *dateString = [formatter stringFromDate:event.startDate];
        [formatter setTimeStyle:NSDateFormatterShortStyle];
        NSString *timeString = nil;
        if (event.endDate) {
            timeString = [NSString stringWithFormat:@"%@ | %@-%@",
                          dateString,
                          [formatter stringFromDate:event.startDate],
                          [formatter stringFromDate:event.endDate]];
        } else {
            timeString = [NSString stringWithFormat:@"%@ | %@",
                          dateString,
                          [formatter stringFromDate:event.startDate]];
        }
        
        // recreate and reattach the subtitle if needed
        // it was deleted if we didn't have a briefLocation
        self.subtitleLabel.text = timeString;
        if (![_subtitleLabel isDescendantOfView:self]) {
            [self addSubview:_subtitleLabel];
        }
    }
}

- (void)setupBookmarkButtonImages
{
    if (_bookmarkedItem) {
        UIImage *buttonImage = nil;
        UIImage *pressedButtonImage = nil;
        if ([_bookmarkedItem isBookmarked]) {
            buttonImage = [UIImage imageWithPathName:@"common/bookmark_on.png"];
            pressedButtonImage = [UIImage imageWithPathName:@"common/bookmark_on_pressed.png"];
        } else {
            buttonImage = [UIImage imageWithPathName:@"common/bookmark_off.png"];
            pressedButtonImage = [UIImage imageWithPathName:@"common/bookmark_off_pressed.png"];
        }
        [_bookmarkButton setImage:buttonImage forState:UIControlStateNormal];
        [_bookmarkButton setImage:pressedButtonImage forState:UIControlStateHighlighted];
    } else {
        [super setupBookmarkButtonImages];
    }
}

- (void)dealloc
{
    [_placeSubtitleLabel release];
    [_placeTitleLabel release];
    [super dealloc];
}

@end
