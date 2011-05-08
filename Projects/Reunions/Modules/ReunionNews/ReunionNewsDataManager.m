#import "ReunionNewsDataManager.h"
#import "NewsDataManager+Protected.h"

@implementation ReunionNewsDataManager


+ (ReunionNewsDataManager *)sharedManager {
	static ReunionNewsDataManager *sharedManager = nil;
	if (sharedManager == nil) {
		sharedManager = [[ReunionNewsDataManager alloc] init];
	}
	return sharedManager;
}


- (NSArray *)searchableCategories {
  return [NSArray arrayWithObject:[[self fetchCategoriesFromCoreData] objectAtIndex:0]];
}

@end
