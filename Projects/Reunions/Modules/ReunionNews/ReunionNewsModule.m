
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import "ReunionNewsModule.h"
#import "ReunionNewsDataManager.h"

@implementation ReunionNewsModule

- (NewsDataManager *)dataManager {
  return [ReunionNewsDataManager sharedManager];
}

@end
