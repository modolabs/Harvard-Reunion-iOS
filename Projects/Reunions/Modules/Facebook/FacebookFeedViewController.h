#import "KGOTableViewController.h"
#import "MITThumbnailView.h"
#import "KGOSocialMediaController+FacebookAPI.h"

@class FacebookModule;

@interface FacebookFeedViewController : KGOTableViewController <FacebookUploadDelegate, UITextViewDelegate> {
    
    FacebookModule *_facebookModule;
    UITextView *_inputView;
    
}

@property(nonatomic, retain) NSArray *feedPosts;

- (void)facebookFeedDidUpdate:(NSNotification *)aNotification;
- (void)postButtonPressed:(id)sender;

@end
