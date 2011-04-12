#import "ReunionMapModule.h"
#import "KGOPlacemark.h"
#import "ReunionMapDetailViewController.h"

@implementation ReunionMapModule

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    
    if ([pageName isEqualToString:LocalPathPageNameDetail]) {
        ReunionMapDetailViewController *detailVC = [[[ReunionMapDetailViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
        
        KGOPlacemark *place = [params objectForKey:@"place"];
        if (place) {
            detailVC.annotation = place;
            //detailVC.placemark = place;
        }
        id<KGODetailPagerController> controller = [params objectForKey:@"pagerController"];
        if (controller) {
            KGODetailPager *pager = [[[KGODetailPager alloc] initWithPagerController:controller delegate:detailVC] autorelease];
            detailVC.pager = pager;
        }
        
        return detailVC;
    }
    
    return [super modulePage:pageName params:params];
}

@end
