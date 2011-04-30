#import "ReunionMapDetailHeaderView.h"
#import "KGOSearchModel.h"
#import "KGOPlacemark.h"
#import "ScheduleEventWrapper.h"
#import "KGOMapCategory.h"
#import "ReunionMapModule.h"
#import "UIKit+KGOAdditions.h"

@implementation ReunionMapDetailHeaderView

- (void)toggleBookmark:(id)sender
{
    if ([self.detailItem isKindOfClass:[ScheduleEventWrapper class]]) {
        
        ScheduleEventWrapper *event = (ScheduleEventWrapper *)self.detailItem;
        NSArray *categoryPath = [NSArray arrayWithObject:EventMapCategoryName];
        KGOPlacemark *placemark = [KGOPlacemark placemarkWithID:event.identifier categoryPath:categoryPath];
        placemark.longitude = [NSNumber numberWithFloat:event.coordinate.longitude];
        placemark.latitude = [NSNumber numberWithFloat:event.coordinate.latitude];
        placemark.bookmarked = [NSNumber numberWithBool:YES];

        if (placemark) {
            _bookmarkedItem = [placemark retain];
        }
        
    } else {
        [super toggleBookmark:sender];
    }
}

- (UILabel *)subtitleLabel
{
    if (!_subtitleLabel) {
        _subtitleLabel = [[UILabel alloc] init];
        _subtitleLabel.backgroundColor = [UIColor clearColor];
        _subtitleLabel.font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyContentSubtitle];
        _subtitleLabel.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyContentSubtitle];
        //_subtitleLabel.numberOfLines = MAX_SUBTITLE_LINES;
    }
    return _subtitleLabel;
}

- (void)setDetailItem:(id<KGOSearchResult>)detailItem
{
    [super setDetailItem:detailItem];
    
    [_bookmarkedItem release];
    _bookmarkedItem = nil;
}

- (CGFloat)headerWidthWithButtons
{
    return self.bounds.size.width - 70;
}

- (void)layoutBookmarkButton
{
    [super layoutBookmarkButton];
    
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
    }
    
}

@end
