#import <UIKit/UIKit.h>

@interface FacebookMediaViewController : UIViewController <UIWebViewDelegate> {
    
    IBOutlet UISegmentedControl *_filterControl;
    IBOutlet UIWebView *_signedInUserView;
    IBOutlet UIScrollView *_scrollView;
    
    // hidden for logged-in users
    IBOutlet UIView *_loginView;
    IBOutlet UILabel *_loginHintLabel;
    IBOutlet UIButton *_loginButton; // login or open facebook

    NSString *_gid; // facebook group id
    
    BOOL facebookUserLoggedIn;
}

- (IBAction)filterValueChanged:(UISegmentedControl *)sender;
- (IBAction)loginButtonPressed:(UIButton *)sender;

- (void)showLoginView;
- (void)hideLoginView;
- (void)showSignedInUserView:(NSNotification *)aNotification;

- (void)facebookDidLogout:(NSNotification *)aNotification;
- (void)facebookDidLogin:(NSNotification *)aNotification;

@end
