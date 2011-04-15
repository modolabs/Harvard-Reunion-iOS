#import "FacebookMediaViewController.h"
#import "KGOSocialMediaController+FacebookAPI.h"
#import "FacebookUser.h"

#import "KGOFoursquareEngine.h"
#import "KGOTheme.h"

@implementation FacebookMediaViewController

@synthesize scrollView = _scrollView;

#pragma mark -

- (IBAction)filterValueChanged:(UISegmentedControl *)sender {
    
    

}

- (IBAction)loginButtonPressed:(UIButton *)sender {
    [[KGOSocialMediaController sharedController] loginFacebook];
}

- (void)showLoginViewAnimated:(BOOL)animated {
    if (_loginView.alpha == 0) {
        if (animated) {
            [UIView animateWithDuration:0.4 animations:^(void) {
                _loginView.alpha = 1;
                
            } completion:^(BOOL finished) {
                if (finished) {
                    _loginView.hidden = NO;
                }
            }];
        } else {
            _loginView.alpha = 1;
            _loginView.hidden = NO;
        }
    } else {
        _loginView.hidden = NO;
    }
}

- (void)hideLoginViewAnimated:(BOOL)animated {
    if (_loginView.alpha != 0) {
        if (animated) {
            [UIView animateWithDuration:0.4 animations:^(void) {
                _loginView.alpha = 0;
                
            } completion:^(BOOL finished) {
                if (finished) {
                    _loginView.hidden = YES;
                }
            }];
        } else {
            _loginView.alpha = 0;
            _loginView.hidden = YES;
        }
    } else {
        _loginView.hidden = YES;
    }
}

#pragma mark -

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_scrollView release];
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
    facebookUserLoggedIn = YES;
    [self hideLoginViewAnimated:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(facebookDidLogout:)
                                                 name:FacebookDidLogoutNotification
                                               object:nil];
}

- (void)facebookDidLogout:(NSNotification *)aNotification
{
    facebookUserLoggedIn = NO;
    [self showLoginViewAnimated:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(facebookDidLogin:)
                                                 name:FacebookDidLoginNotification
                                               object:nil];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (facebookUserLoggedIn) {
        [self hideLoginViewAnimated:NO];
    }
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
