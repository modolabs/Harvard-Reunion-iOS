#import "ReunionHomeViewController.h"
#import "ReunionHomeModule.h"

@implementation ReunionHomeViewController

@synthesize homeModule;

- (void)hideLoadingViewIfLoginOK
{
    if (![self.homeModule homeScreenConfig]) {
        return;
    }
    
    [super hideLoadingViewIfLoginOK];
}

@end
