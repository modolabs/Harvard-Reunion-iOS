
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

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
@interface ReunionMapDetailViewController : UIViewController <KGODetailPagerDelegate,
UIWebViewDelegate, KGODetailPageHeaderDelegate, MITThumbnailDelegate,
KGORequestDelegate, UITableViewDelegate, UITableViewDataSource> {
    
    ReunionMapDetailHeaderView *_headerView;

    MITThumbnailView *_thumbView;
    UIWebView *_webView;
    
    KGOHTMLTemplate *_htmlTemplate;
    
    NSString *_placemarkInfo;
    KGORequest *_placemarkInfoRequest;
    NSString *_imageURL;
    UIImage *_image;
    
    UITableView *_tableView;
    
    NSInteger _googleSection;
    NSInteger _eventSection;
    NSInteger _detailSection;
}

@property(nonatomic, retain) KGOPlacemark *placemark;
@property(nonatomic, retain) id<MKAnnotation, KGOSearchResult> annotation;
@property(nonatomic, retain) KGODetailPager *pager;
@property(nonatomic, retain) UITableView *tableView;

- (void)loadDetailSection;
- (void)loadAnnotationContent;

@end
