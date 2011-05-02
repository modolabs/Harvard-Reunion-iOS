#import <UIKit/UIKit.h>
#import "FacebookMediaViewController.h"
#import "KGOSocialMediaController.h"
#import "Facebook.h"
#import "MITThumbnailView.h"
#import "IconGrid.h"
#import "FacebookVideo.h"

typedef BOOL (^VideoTest)(FacebookVideo *video);

// still deciding how FB wrapper work should be allocated
// between KGOSocialMediaController and this class.
// since this is a facebook module it would be fine to put as much fb stuff in here as we want
@interface FacebookVideosViewController : FacebookMediaViewController 
<IconGridDelegate, MITThumbnailDelegate> {

//    UITableView *_tableView;
    
    NSMutableArray *_videos;
    NSMutableArray *_displayedVideos;
    NSMutableSet *_videoIDs;
    CGFloat resizeFactor;
}

@property (nonatomic, retain) IconGrid *iconGrid;
@property (nonatomic, retain) VideoTest currentFilterBlock;

@end
