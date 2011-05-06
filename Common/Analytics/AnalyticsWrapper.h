/* AnalyticsWrapper.h
 * This tracker is not thread safe.
 */

#import <Foundation/Foundation.h>
#import "GANTracker.h"

typedef enum {
    KGOAnalyticsProviderNone,
    KGOAnalyticsProviderGoogle,
} KGOAnalyticsProvider;


@interface AnalyticsWrapper : NSObject <GANTrackerDelegate> {
    
	NSDictionary *_preferences;
    KGOAnalyticsProvider _provider;

    NSString *_trackingGroup;
}

+ (AnalyticsWrapper *)sharedWrapper;
- (void)shutdown;

- (void)setup;

- (void)trackPageview:(NSString *)pageID;
- (void)trackEvent:(NSString *)event action:(NSString *)action label:(NSString *)label;

- (NSString *)trackingGroup; // for use when users are segmented into groups
- (void)trackGroupAction:(NSString *)action label:(NSString *)label;

@property KGOAnalyticsProvider provider;

@end
