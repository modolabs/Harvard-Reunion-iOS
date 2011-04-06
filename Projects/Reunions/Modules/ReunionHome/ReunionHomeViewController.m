#import "ReunionHomeViewController.h"
#import "ReunionHomeModule.h"

@implementation ReunionHomeViewController

@synthesize homeModule;

- (void)loginDidComplete:(NSNotification *)aNotification
{
    if (![self.homeModule homeScreenConfig]) {
        return;
    }
    
    [super loginDidComplete:aNotification];
}

@end
