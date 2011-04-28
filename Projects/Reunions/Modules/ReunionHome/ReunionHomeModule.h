#import "HomeModule.h"
#import "KGORequest.h"

extern NSString * const HomeScreenConfigPrefKey;

@interface ReunionHomeModule : HomeModule <KGORequestDelegate> {
    
    NSDictionary *_homeScreenConfig;
    KGORequest *_request;
}

- (NSString *)fbGroupID;
- (NSString *)fbGroupName;
- (BOOL)fbGroupIsOld;
- (NSString *)twitterHashTag;
- (NSString *)reunionName;
- (NSString *)reunionDateString;
- (NSString *)reunionNumber;
- (NSString *)reunionYear;

- (NSDictionary *)homeScreenConfig;
- (NSArray *)moduleOrder;

- (void)logout;

@end
