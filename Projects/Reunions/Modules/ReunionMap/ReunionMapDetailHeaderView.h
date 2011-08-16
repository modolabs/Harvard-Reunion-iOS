
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import "KGODetailPageHeaderView.h"

@interface ReunionMapDetailHeaderView : KGODetailPageHeaderView {
    
    id<KGOSearchResult> _bookmarkedItem;
    
    UILabel *_placeTitleLabel;
    UILabel *_placeSubtitleLabel;
}

@end
