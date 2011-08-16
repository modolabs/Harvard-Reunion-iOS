
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import "ReunionMapDetailViewController.h"

@interface ReunionMapTabletDetailController : ReunionMapDetailViewController <UIScrollViewDelegate> {
    
    UIScrollView *_scrollView;
    CGFloat _currentTableWidth;
    BOOL _canShowThumbnail;
    
    NSArray *_detailFields;
}

@end
