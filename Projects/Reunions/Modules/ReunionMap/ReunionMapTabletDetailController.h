
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import "ReunionMapDetailViewController.h"

@interface ReunionMapTabletDetailView : UIScrollView {
}
@property(nonatomic, retain) UIView *hitBoxView;

@end


@interface ReunionMapTabletDetailController : ReunionMapDetailViewController <UIScrollViewDelegate> {
    
    UIScrollView *_scrollView;
    CGFloat _currentTableWidth;
    BOOL _canShowThumbnail;
    
    NSArray *_detailFields;
}

@end
