#import "ReunionMapDetailViewController.h"

@interface ReunionMapTabletDetailController : ReunionMapDetailViewController <UIScrollViewDelegate> {
    
    UIScrollView *_scrollView;
    CGFloat _currentTableWidth;
    BOOL _canShowThumbnail;
    
    NSArray *_detailFields;
}

@end
