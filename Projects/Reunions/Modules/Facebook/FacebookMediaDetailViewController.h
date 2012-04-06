
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import <UIKit/UIKit.h>
#import "KGODetailPager.h"
#import "MITThumbnailView.h"
#import "MediaContainerView.h"
#import "FacebookCommentViewController.h"
#import "KGOSocialMediaController+FacebookAPI.h"
#import "KGOToolbar.h"

#define MAXIMUM_IMAGE_HEIGHT 500

@class FacebookParentPost;

@interface FacebookMediaDetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate,
KGODetailPagerController, KGODetailPagerDelegate, FacebookUploadDelegate, FacebookCommentDelegate> {
    IBOutlet UITableView *_tableView;
    IBOutlet UIButton *_commentButton;
    IBOutlet UIButton *_likeButton;
    IBOutlet UIButton *_bookmarkButton;
    IBOutlet UIView *_buttonsBar;
    
    IBOutlet MediaContainerView *_mediaView;
    IBOutlet UIView *_mediaPreviewView;
    IBOutlet UIView *_mediaImageBackgroundView;
    
    IBOutlet KGOToolbar *actionsToolbar;
    IBOutlet UIView *actionToolbarRoot;
    IBOutlet UIBarButtonItem *pagerBarItem;
    IBOutlet UIButton *backButton;
    
    UITapGestureRecognizer *_tapRecognizer;
    
    NSArray *_comments;
    
    UIInterfaceOrientation displayedOrientation;
}

@property (nonatomic, retain) NSArray *posts;
@property NSInteger initialIndex;
@property (nonatomic, retain) FacebookParentPost *post;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) NSString *moduleTag;
@property (readonly) MediaContainerView *mediaView;
@property (nonatomic, retain) KGOToolbar *actionsToolbar;
@property (nonatomic, retain) UITapGestureRecognizer *tapRecoginizer;


- (IBAction)commentButtonPressed:(id)sender;
- (IBAction)likeButtonPressed:(id)sender;
- (IBAction)bookmarkButtonPressed:(id)sender;
- (IBAction)closeButtonPressed:(id)sender;
- (IBAction)uploadButtonPressed:(id)sender;
- (NSString *)identifierForBookmark;
- (NSString *)mediaTypeForBookmark;
- (NSString *)mediaTypeHumanReadableName;
- (NSString *)closeButtonName;

- (void)displayPost;
- (NSString *)postTitle;

- (void)getCommentsForPost;
- (void)didReceiveComments:(id)result;

- (void)didLikePost:(id)result;
- (void)didUnlikePost:(id)result;

- (BOOL)hideToolbarsInLandscape;


@end
