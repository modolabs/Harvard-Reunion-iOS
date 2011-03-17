#import "FacebookMediaViewController.h"
#import "KGOSocialMediaController+FacebookAPI.h"
#import "FacebookUser.h"

@implementation FacebookMediaViewController

#pragma mark -

- (IBAction)filterValueChanged:(UISegmentedControl *)sender {

}

- (IBAction)loginButtonPressed:(UIButton *)sender {
    [[KGOSocialMediaController sharedController] loginFacebook];
}

- (void)showLoginView {
    if (_loginView.alpha == 0) {
        [UIView animateWithDuration:0.4 animations:^(void) {
            _loginView.alpha = 1;
            
        } completion:^(BOOL finished) {
            if (finished) {
                _loginView.hidden = NO;
            }
        }];
    } else {
        _loginView.hidden = NO;
    }
}

- (void)hideLoginView {
    if (_loginView.alpha != 0) {
        [UIView animateWithDuration:0.4 animations:^(void) {
            _loginView.alpha = 0;
            
        } completion:^(BOOL finished) {
            if (finished) {
                _loginView.hidden = YES;
            }
        }];
    } else {
        _loginView.hidden = YES;
    }
    
    [self showSignedInUserView:nil];
}

- (void)showSignedInUserView:(NSNotification *)aNotification {
    NSString *username;
    FacebookUser *user = [[KGOSocialMediaController sharedController] currentFacebookUser];
    if (user) {
        username = user.name;
        [[NSNotificationCenter defaultCenter] removeObserver:self name:FacebookDidGetSelfInfoNotification object:nil];
    } else {
        username = @"(retrieving details...)";
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(showSignedInUserView:)
                                                     name:FacebookDidGetSelfInfoNotification
                                                   object:nil];
    }
    NSString *html = [NSString stringWithFormat:
                      @"<body style=\"background-color:transparent\">"
                      "Logged in as %@ (<a href=\"#\" style=\"color:#9999ff\">Not You?</a>)"
                      "</body>", username];
    [_signedInUserView loadHTMLString:html baseURL:nil];
}

#pragma mark - Web view delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([[request.URL absoluteString] rangeOfString:@"#"].location != NSNotFound) {
        [[KGOSocialMediaController sharedController] logoutFacebook];
        [self showLoginView];
        return NO;
    }
    return YES;
}

#pragma mark -

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark facebook wrapper

- (void)facebookDidLogin:(NSNotification *)aNotification
{
    [self hideLoginView];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(facebookDidLogout:)
                                                 name:FacebookDidLogoutNotification
                                               object:nil];
}

- (void)facebookDidLogout:(NSNotification *)aNotification
{
    [self showLoginView];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(facebookDidLogin:)
                                                 name:FacebookDidLoginNotification
                                               object:nil];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _loginHintLabel.text = NSLocalizedString(@"Reunion photos are posted etc etc etc.", nil);
    [_loginButton setTitle:@"Sign in to Facebook" forState:UIControlStateNormal];
}

- (void)viewWillAppear:(BOOL)animated {
    
    if (![[KGOSocialMediaController sharedController] isFacebookLoggedIn]) {
        [self facebookDidLogout:nil];
    } else {
        [self facebookDidLogin:nil];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
