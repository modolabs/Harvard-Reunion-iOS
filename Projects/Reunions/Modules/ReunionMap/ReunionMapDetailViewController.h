#import <UIKit/UIKit.h>
#import "KGODetailPager.h"
#import "ConnectionWrapper.h"
#import "MITThumbnailView.h"
#import "ReunionDetailPageHeaderView.h"

@class KGOPlacemark, KGOHTMLTemplate;

// not subclassing MapDetailViewController b/c we don't want a tabbed view
@interface ReunionMapDetailViewController : UITableViewController <KGODetailPagerDelegate,
UIWebViewDelegate, KGODetailPageHeaderDelegate, MITThumbnailDelegate> {
    
    ReunionDetailPageHeaderView *_headerView;
    CGFloat _webViewHeight;
    CGFloat _thumbViewHeight;
    KGOHTMLTemplate *_htmlTemplate;
    
}

@property(nonatomic, retain) KGOPlacemark *placemark;
@property(nonatomic, retain) KGODetailPager *pager;

@end
