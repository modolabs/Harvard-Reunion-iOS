#import "KGOSidebarFrameViewController.h"

@class ReunionHomeModule;

@interface ReunionSidebarFrameViewController : KGOSidebarFrameViewController {
    
    NSArray *_subclassPrimaryModules;
    NSArray *_subclassSecondaryModules;
    
    NSMutableArray *_hiddenRotatingWidgets;
}

@property(nonatomic, assign) ReunionHomeModule *homeModule;

@end
