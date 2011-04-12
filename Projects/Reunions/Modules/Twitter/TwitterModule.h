#import "MicroblogModule.h"
#import "TwitterSearch.h"

@interface TwitterModule : MicroblogModule <TwitterSearchDelegate> {
    
    NSTimer *_statusPoller;
    TwitterSearch *_twitterSearch;

    NSArray *_latestTweets;
    
    NSDate *_lastUpdate;
    NSDateFormatter *_twitterDateFormatter;
    
    NSString *_hashTag;
    
    // ipad only
    UINavigationController *_modalTwitterController;
    UIView *_scrim;
}

- (void)startPollingStatusUpdates;
- (void)stopPollingStatusUpdates;
- (void)requestStatusUpdates:(NSTimer *)aTimer;

- (void)didLogin:(NSNotification *)aNotification;

- (void)hideModalTwitterController:(id)sender;

@property (nonatomic, readonly) NSDateFormatter *twitterDateFormatter;
@property (nonatomic, readonly) NSArray *latestTweets;

@end
