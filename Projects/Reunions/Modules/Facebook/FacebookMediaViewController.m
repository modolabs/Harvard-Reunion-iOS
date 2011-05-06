#import "FacebookMediaViewController.h"
#import "KGOSocialMediaController+FacebookAPI.h"
#import "FacebookUser.h"
#import "UIKit+KGOAdditions.h"
#import "KGOFoursquareEngine.h"
#import "KGOTheme.h"
#import "KGOSegmentedControl.h"
#import "KGOToolbar.h"

@implementation FacebookMediaViewController

@synthesize scrollView = _scrollView;
@synthesize subheadToolbar;

#pragma mark -

- (IBAction)filterValueChanged:(UISegmentedControl *)sender {
    
    

}

- (IBAction)loginButtonPressed:(UIButton *)sender {
    [[KGOSocialMediaController facebookService] signin];
}

- (IBAction)uploadButtonPressed:(id)sender {
    DLog(@"uplaodButtonPressed should be overridden in a subclass.");
}

- (BOOL)implementsUpload {
    return NO;
}

- (void)showLoginViewAnimated:(BOOL)animated {
    if (_loginView.alpha == 0) {
        if (animated) {
            [UIView animateWithDuration:0.4 animations:^(void) {
                _loginView.alpha = 1;
                _scrollView.alpha = 0;
                self.subheadToolbar.alpha = 0;
                
            } completion:^(BOOL finished) {
                if (finished) {
                    _loginView.hidden = NO;
                    _scrollView.hidden = YES;
                    self.subheadToolbar.hidden = YES;
                }
            }];
        } else {
            _scrollView.alpha = 0;
            _scrollView.hidden = YES;

            _loginView.alpha = 1;
            _loginView.hidden = NO;
            
            self.subheadToolbar.alpha = 0;
            self.subheadToolbar.hidden = YES;
        }
    } else {
        _loginView.hidden = NO;
        _scrollView.hidden = YES;
        self.subheadToolbar.hidden = YES;
    }
}

- (void)hideLoginViewAnimated:(BOOL)animated {
    if (_loginView.alpha != 0) {
        if (animated) {
            [UIView animateWithDuration:0.4 animations:^(void) {
                _loginView.alpha = 0;
                _scrollView.alpha = 1;
                self.subheadToolbar.alpha = 1;
                
            } completion:^(BOOL finished) {
                if (finished) {
                    _loginView.hidden = YES;
                    _scrollView.hidden = NO;
                    self.subheadToolbar.hidden = NO;
                }
            }];
        } else {
            _loginView.alpha = 0;
            _loginView.hidden = YES;
            
            _scrollView.alpha = 1;
            _scrollView.hidden = NO;
            
            self.subheadToolbar.alpha = 1;
            self.subheadToolbar.hidden = NO;
        }
    } else {
        _loginView.hidden = YES;
        _scrollView.hidden = NO;
        self.subheadToolbar.hidden = NO;
    }
}

#pragma mark -

- (void)dealloc
{
    [subheadToolbar release];
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
    [self hideLoginViewAnimated:YES];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(facebookDidLogout:)
                                                 name:FacebookDidLogoutNotification
                                               object:nil];
}

- (void)facebookDidLogout:(NSNotification *)aNotification
{
    [self showLoginViewAnimated:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(facebookDidLogin:)
                                                 name:FacebookDidLoginNotification
                                               object:nil];
}

- (void)refreshMyMedia {
    if(_filterControl.selectedSegmentIndex == kMyUploadsSegment) {
        [self refreshMedia];
    }
}

- (void)refreshMedia {
    NSAssert(NO, @"refreshMedia must been overridden");
}

#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
    
    [_filterControl addTarget:self action:@selector(filterValueChanged:) forControlEvents:UIControlEventValueChanged];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        _filterControl.tabFont = [UIFont boldSystemFontOfSize:13];
    } else {
        _filterControl.tabFont = [UIFont boldSystemFontOfSize:12];
    }
    
    _filterControl.tabPadding = 6;
    
    self.subheadToolbar.backgroundImage = [UIImage imageWithPathName:@"common/subheadbar_background"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    _loginHintLabel.text = NSLocalizedString(@"Photos and videos are posted to the Facebook group page for each class. To view and comment on them, you must sign into Facebook, and you must be a member of the class Facebook group.", nil);
    [_loginButton setTitle:@"Sign in to Facebook" forState:UIControlStateNormal];
    UIImage *image = [[UIImage imageWithPathName:@"common/red-button.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:10];
    [_loginButton setBackgroundImage:image forState:UIControlStateNormal];

    if ([[KGOSocialMediaController facebookService] isSignedIn]) {
        [self facebookDidLogin:nil];
    } else {
        [self facebookDidLogout:nil];
    }

    if ([self implementsUpload]) {
        if(_uploadButton) {
            UIImage *toolbarButtonImage = [[UIImage imageWithPathName:@"common/toolbar-button.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:10];
            [_uploadButton setBackgroundImage:toolbarButtonImage forState:UIControlStateNormal];
        }
    } else {
        [_uploadButton removeFromSuperview];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshMyMedia) name:FacebookDidGetSelfInfoNotification object:nil];
    
    [pool release];
}

- (void)viewWillAppear:(BOOL)animated
{
    if ([[KGOSocialMediaController facebookService] isSignedIn]) {
        [self facebookDidLogin:nil];
    } else {
        [self facebookDidLogout:nil];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    } else {
        return (interfaceOrientation == UIInterfaceOrientationPortrait);
    }
}

@end
