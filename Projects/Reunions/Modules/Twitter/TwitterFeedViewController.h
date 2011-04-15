#import "KGOTableViewController.h"
#import "TwitterViewController.h"

@class TwitterModule;

@interface TwitterFeedViewController : KGOTableViewController <TwitterViewControllerDelegate> {
    
    // keep a copy ourselves since TwitterModule's might update on us
    TwitterModule *twitterModule;
    
    UITextView *_inputView;
    
}

@property(nonatomic, retain) NSArray *latestTweets;

- (void)twitterFeedDidUpdate:(NSNotification *)aNotification;
- (void)tweetButtonPressed:(id)sender;

- (void)showInputView;
- (void)hideInputView;

@end
