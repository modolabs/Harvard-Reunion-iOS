#import "KGODetailPageHeaderView.h"

@interface ReunionMapDetailHeaderView : KGODetailPageHeaderView {
    
    id<KGOSearchResult> _bookmarkedItem;
    
    UILabel *_placeTitleLabel;
    UILabel *_placeSubtitleLabel;
}

@end
