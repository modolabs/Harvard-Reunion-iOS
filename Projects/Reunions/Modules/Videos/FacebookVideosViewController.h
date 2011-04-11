#import <UIKit/UIKit.h>
#import "KGOSocialMediaController.h"
#import "Facebook.h"
#import "FacebookMediaViewController.h"
#import "MITThumbnailView.h"

@class IconGrid;

// still deciding how FB wrapper work should be allocated
// between KGOSocialMediaController and this class.
// since this is a facebook module it would be fine to put as much fb stuff in here as we want
@interface FacebookVideosViewController : FacebookMediaViewController <UITableViewDataSource, UITableViewDelegate, MITThumbnailDelegate> {

    UITableView *_tableView;
    
    NSMutableArray *_videos;
    NSMutableSet *_videoIDs;
    NSMutableDictionary *_videosForThumbSrc;
}

@end
