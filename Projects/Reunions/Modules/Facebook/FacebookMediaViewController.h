#import <UIKit/UIKit.h>

typedef enum {
    kAllMediaObjectsSegment = 0,
    kMyUploadsSegment,
    kBookmarksSegment
}
FacebookMediaSegmentIndexes;

@class KGOSegmentedControl, KGOToolbar;

@interface FacebookMediaViewController : UIViewController 
<UINavigationControllerDelegate> {

    IBOutlet KGOSegmentedControl *_filterControl;
    IBOutlet UIScrollView *_scrollView;
    IBOutlet KGOToolbar *subheadToolbar;
    
    // hidden for logged-in users
    IBOutlet UIView *_loginView;
    IBOutlet UILabel *_loginHintLabel;
    IBOutlet UIButton *_loginButton; // login or open facebook
    
    // ipad views
    IBOutlet UIBarButtonItem *_uploadBarButtonItem;
    IBOutlet UIButton *_uploadButton;

    NSString *_gid; // facebook group id
    
    BOOL facebookUserLoggedIn;
}

- (IBAction)filterValueChanged:(UISegmentedControl *)sender;
- (IBAction)loginButtonPressed:(UIButton *)sender;
- (IBAction)uploadButtonPressed:(id)sender;

- (BOOL)implementsUpload;

- (void)showLoginViewAnimated:(BOOL)animated;
- (void)hideLoginViewAnimated:(BOOL)animated;

- (void)facebookDidLogout:(NSNotification *)aNotification;
- (void)facebookDidLogin:(NSNotification *)aNotification;

- (void)refreshMyMedia; // used to indicate that facebook has returned the current user id info
- (void)refreshMedia;

- (void)setupLoginStatusStrings;

@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) KGOToolbar *subheadToolbar;

@end
