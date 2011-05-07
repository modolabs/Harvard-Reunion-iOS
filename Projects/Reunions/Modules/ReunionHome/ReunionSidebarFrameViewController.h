#import "KGOSidebarFrameViewController.h"

#define FEED_VIEW_CONTROLLER_TAG 87
#define FEED_VIEW_CONTROLLER_SCRIM_TAG 51

@class ReunionHomeModule;

@interface ReunionSidebarFrameViewController : KGOSidebarFrameViewController {
    
    NSArray *_subclassPrimaryModules;
    NSArray *_subclassSecondaryModules;
    
    NSMutableArray *_hiddenRotatingWidgets;
}

@property(nonatomic, assign) ReunionHomeModule *homeModule;

@end
