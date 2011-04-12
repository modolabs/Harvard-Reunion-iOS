#import "HomeModule.h"
#import "KGORequest.h"

extern NSString * const HomeScreenConfigPrefKey;

@interface ReunionHomeModule : HomeModule <KGORequestDelegate> {
    
    NSDictionary *_homeScreenConfig;
    KGORequest *_request;
}

- (NSString *)fbGroupID;
- (NSString *)fbGroupName;
- (NSString *)twitterHashTag;
- (NSString *)reunionName;
- (NSString *)reunionDateString;
- (NSString *)reunionNumber;

- (NSDictionary *)homeScreenConfig;
- (NSArray *)moduleOrder;

@end
