#import "KGOTableViewController.h"

@class TwitterModule;

@interface TwitterFeedViewController : KGOTableViewController {
    
    // keep a copy ourselves since TwitterModule's might update on us
    TwitterModule *twitterModule;
    
}

@property(nonatomic, retain) NSArray *latestTweets;

- (void)twitterFeedDidUpdate:(NSNotification *)aNotification;
- (void)tweetButtonPressed:(id)sender;

@end
