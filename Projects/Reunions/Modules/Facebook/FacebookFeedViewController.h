#import "KGOTableViewController.h"
#import "MITThumbnailView.h"

@class FacebookModule;

@interface FacebookFeedViewController : KGOTableViewController {
    
    FacebookModule *_facebookModule;
    
}

@property(nonatomic, retain) NSArray *feedPosts;

- (void)facebookFeedDidUpdate:(NSNotification *)aNotification;
- (void)postButtonPressed:(id)sender;

@end
