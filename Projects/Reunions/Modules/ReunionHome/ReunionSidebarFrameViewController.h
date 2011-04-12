#import "KGOSidebarFrameViewController.h"

@class ReunionHomeModule;

@interface ReunionSidebarFrameViewController : KGOSidebarFrameViewController {
    
    NSArray *_subclassPrimaryModules;
    NSArray *_subclassSecondaryModules;
}

@property(nonatomic, assign) ReunionHomeModule *homeModule;

@end
