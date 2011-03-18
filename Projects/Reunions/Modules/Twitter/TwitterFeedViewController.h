#import "KGOTableViewController.h"

@class TwitterModule;

@interface TwitterFeedViewController : KGOTableViewController {
    
    // keep a copy ourselves since TwitterModule's might update on us
    TwitterModule *twitterModule;
    
    UIView *_loginView;
    UIView *_sendTweetView;
}

@property(nonatomic, retain) NSArray *latestTweets;

- (void)twitterFeedDidUpdate:(NSNotification *)aNotification;
- (void)loginButtonPressed:(UIButton *)sender;
- (void)sendButtonPressed:(UIButton *)sender;

@end
