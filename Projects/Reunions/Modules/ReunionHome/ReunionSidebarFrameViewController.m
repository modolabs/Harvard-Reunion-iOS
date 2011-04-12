#import "ReunionSidebarFrameViewController.h"
#import "ReunionHomeModule.h"
#import "LoginModule.h"
#import "KGOHomeScreenWidget.h"
#import "TwitterModule.h"
#import "FacebookModule.h"

@implementation ReunionSidebarFrameViewController

@synthesize homeModule;

- (void)loginDidComplete:(NSNotification *)aNotification
{
    if (![self.homeModule homeScreenConfig]) {
        return;
    }
    
    [super loginDidComplete:aNotification];
    
    if (self.primaryModules.count) {
        KGOModule *defaultModule = [self.primaryModules objectAtIndex:0];
        [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameHome
                               forModuleTag:defaultModule.tag
                                     params:nil];
    }
}

- (void)loadModules {
    // from superclass
    NSArray *modules = [KGO_SHARED_APP_DELEGATE() modules];
    NSMutableArray *primary = [NSMutableArray array];
    NSMutableArray *secondary = [NSMutableArray array];
    
    for (KGOModule *aModule in modules) {
        // special case for home module
        if ([aModule isKindOfClass:[ReunionHomeModule class]]) {
            self.homeModule = (ReunionHomeModule *)aModule;
        }
        
        if (aModule.hidden) {
            continue;
        }
        
        // TODO: make the home API report whether modules are secondary
        if ([aModule isKindOfClass:[LoginModule class]]) {
            aModule.secondary = YES;
        }
        
        if (aModule.secondary) {
            [secondary addObject:aModule];
        } else {
            [primary addObject:aModule];
        }
    }
    
    [_subclassSecondaryModules release];
    _subclassSecondaryModules = [secondary copy];
    
    [_subclassPrimaryModules release];
    NSArray *moduleOrder = [self.homeModule moduleOrder];
    _subclassPrimaryModules = [[primary sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSInteger order1 = [moduleOrder indexOfObject:[(KGOModule *)obj1 tag]];
        NSInteger order2 = [moduleOrder indexOfObject:[(KGOModule *)obj2 tag]];
        if (order1 > order2)
            return NSOrderedDescending;
        else
            return (order1 < order2) ? NSOrderedAscending : NSOrderedSame;
    }] retain];
}

- (NSArray *)primaryModules
{
    return _subclassPrimaryModules;
}

- (NSArray *)secondaryModules
{
    return _subclassSecondaryModules;
}

- (void)refreshWidgets
{
    [super refreshWidgets];
    
    for (KGOHomeScreenWidget *aWidget in [self widgetViews]) {
        if (aWidget.tag == CHAT_BUBBLE_TAG) {
            CGRect frame = aWidget.frame;
            frame.origin.y = self.view.bounds.size.height - frame.size.height - 100;
            if (UIInterfaceOrientationIsPortrait([self interfaceOrientation])) {
                frame.origin.x = 10;
            } else {
                frame.origin.x = self.view.bounds.size.width - frame.size.width - 10;
            }
            aWidget.frame = frame;
            
        } else if ([aWidget.module isKindOfClass:[FacebookModule class]]) {
            CGRect frame = aWidget.frame;            
            if (UIInterfaceOrientationIsPortrait([self interfaceOrientation])) {
                frame.origin.x = frame.size.width + 6 * 2;
            } else {
                frame.origin.x = self.view.bounds.size.width - frame.size.width - 6;
            }
            frame.origin.y = self.view.bounds.size.height - frame.size.height;
            aWidget.frame = frame;
            
        } else if ([aWidget.module isKindOfClass:[TwitterModule class]]) {
            CGRect frame = aWidget.frame;
            if (UIInterfaceOrientationIsPortrait([self interfaceOrientation])) {
                frame.origin.x = 10;
            } else {
                frame.origin.x = self.view.bounds.size.width - frame.size.width * 2 - 6 * 2;
            }
            frame.origin.y = self.view.bounds.size.height - frame.size.height;
            aWidget.frame = frame;
        }
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    _hiddenRotatingWidgets = [[NSMutableArray alloc] init];

    for (KGOHomeScreenWidget *aWidget in [self widgetViews]) {
        if ([aWidget.module isKindOfClass:[MicroblogModule class]]) {
            if (!aWidget.hidden) {
                [_hiddenRotatingWidgets addObject:aWidget];
                aWidget.hidden = YES;
            }
        }
    }
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    for (KGOHomeScreenWidget *aWidget in _hiddenRotatingWidgets) {
        aWidget.hidden = NO;
    }
    [_hiddenRotatingWidgets release];
    _hiddenRotatingWidgets = nil;
}

@end
