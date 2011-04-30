#import <UIKit/UIKit.h>
#import "KGODetailPager.h"
#import "ConnectionWrapper.h"
#import "MITThumbnailView.h"
#import "KGODetailPageHeaderView.h"
#import "ReunionMapDetailHeaderView.h"
#import "KGORequest.h"

@protocol MKAnnotation;
@class KGOPlacemark, KGOHTMLTemplate;

// not subclassing MapDetailViewController b/c we don't want a tabbed view
@interface ReunionMapDetailViewController : UITableViewController <KGODetailPagerDelegate,
UIWebViewDelegate, KGODetailPageHeaderDelegate, MITThumbnailDelegate,
KGORequestDelegate> {
    
    ReunionMapDetailHeaderView *_headerView;

    MITThumbnailView *_thumbView;
    UIWebView *_webView;
    
    KGOHTMLTemplate *_htmlTemplate;
    
    NSString *_placemarkInfo;
    KGORequest *_placemarkInfoRequest;
    NSString *_imageURL;
    UIImage *_image;
}

//@property(nonatomic, retain) KGOPlacemark *placemark;
@property(nonatomic, retain) id<MKAnnotation, KGOSearchResult> annotation;
@property(nonatomic, retain) KGODetailPager *pager;

@end
