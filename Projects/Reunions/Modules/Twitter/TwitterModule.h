#import "MicroblogModule.h"
#import "TwitterSearch.h"

@interface TwitterModule : MicroblogModule <TwitterSearchDelegate> {
    
    NSTimer *_statusPoller;
    TwitterSearch *_twitterSearch;

    NSArray *_latestTweets;
    
    NSDate *_lastUpdate;
    NSDateFormatter *_twitterDateFormatter;
    
    NSString *_hashTag;
}

- (void)startPollingStatusUpdates;
- (void)stopPollingStatusUpdates;
- (void)requestStatusUpdates:(NSTimer *)aTimer;

- (void)didLogin:(NSNotification *)aNotification;

@property (nonatomic, readonly) NSDateFormatter *twitterDateFormatter;
@property (nonatomic, readonly) NSArray *latestTweets;

@end
