#import "ReunionNewsModule.h"
#import "ReunionNewsDataManager.h"

@implementation ReunionNewsModule

- (NewsDataManager *)dataManager {
  return [ReunionNewsDataManager sharedManager];
}

@end
