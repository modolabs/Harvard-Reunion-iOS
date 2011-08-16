
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import "KGOTableViewController.h"
#import "TwitterViewController.h"

@class TwitterModule;

@interface TwitterFeedViewController : KGOTableViewController <TwitterViewControllerDelegate, UITextViewDelegate> {
    
    // keep a copy ourselves since TwitterModule's might update on us
    TwitterModule *twitterModule;
    
    UITextView *_inputView;
    
}

@property(nonatomic, retain) NSArray *latestTweets;

- (void)twitterFeedDidUpdate:(NSNotification *)aNotification;
- (void)tweetButtonPressed:(id)sender;

@end
