#import "MicroblogModule.h"
#import "TwitterSearch.h"

@interface TwitterModule : MicroblogModule <TwitterSearchDelegate> {
    
    NSTimer *_statusPoller;
    TwitterSearch *_twitterSearch;

    NSArray *_latestTweets;
    
    // TODO: parse the date and use that instead
    NSString *_lastUpdate;
    
}

- (void)startPollingStatusUpdates;
- (void)stopPollingStatusUpdates;
- (void)requestStatusUpdates:(NSTimer *)aTimer;

@property (nonatomic, readonly) NSArray *latestTweets;

@end
