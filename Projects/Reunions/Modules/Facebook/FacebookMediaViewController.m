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
@synthesize photoPickerPopover;
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


- (void)showLoginViewAnimated:(BOOL)animated {
    if (_loginView.alpha == 0) {
        if (animated) {
            [UIView animateWithDuration:0.4 animations:^(void) {
                _loginView.alpha = 1;
                _scrollView.alpha = 0;
                
            } completion:^(BOOL finished) {
                if (finished) {
                    _loginView.hidden = NO;
                    _scrollView.hidden = YES;
                }
            }];
        } else {
            _scrollView.alpha = 0;
            _scrollView.hidden = YES;

            _loginView.alpha = 1;
            _loginView.hidden = NO;
        }
    } else {
        _loginView.hidden = NO;
        _scrollView.hidden = YES;
    }
}

- (void)hideLoginViewAnimated:(BOOL)animated {
    if (_loginView.alpha != 0) {
        if (animated) {
            [UIView animateWithDuration:0.4 animations:^(void) {
                _loginView.alpha = 0;
                _scrollView.alpha = 1;
                
            } completion:^(BOOL finished) {
                if (finished) {
                    _loginView.hidden = YES;
                    _scrollView.hidden = NO;
                }
            }];
        } else {
            _loginView.alpha = 0;
            _loginView.hidden = YES;
            
            _scrollView.alpha = 1;
            _scrollView.hidden = NO;
        }
    } else {
        _loginView.hidden = YES;
        _scrollView.hidden = NO;
    }
}

#pragma mark -

- (void)dealloc
{
    [subheadToolbar release];
    [photoPickerPopover release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_scrollView release];
    [_hiddenToolbarItems release];
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
    
    if (self.subheadToolbar && !self.subheadToolbar.items.count && _hiddenToolbarItems.count) {
        self.subheadToolbar.items = _hiddenToolbarItems;
        [_hiddenToolbarItems release];
        _hiddenToolbarItems = nil;
    }
    DLog(@"toolbar items: %@", self.subheadToolbar.items);

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(facebookDidLogout:)
                                                 name:FacebookDidLogoutNotification
                                               object:nil];
}

- (void)facebookDidLogout:(NSNotification *)aNotification
{
    [self showLoginViewAnimated:YES];

    if (self.subheadToolbar.items.count) {
        [_hiddenToolbarItems release];
        _hiddenToolbarItems = [self.subheadToolbar.items copy];
        self.subheadToolbar.items = nil;
    }
    DLog(@"toolbar items: %@", self.subheadToolbar.items);
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(facebookDidLogin:)
                                                 name:FacebookDidLoginNotification
                                               object:nil];
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
    
    _filterControl.tabPadding = 3;
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
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark Photo upload

- (void)showUploadPhotoController:(id)sender
{
    UIImagePickerController *picker = 
    [[[UIImagePickerController alloc] init] autorelease];
    picker.delegate = self;
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    } else {
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // Show the popover if it is not already there.
        if (!self.photoPickerPopover) {            
            // Assumes that the sender is a bar button item.
            if ([sender isKindOfClass:[UIBarButtonItem class]]) {
                self.photoPickerPopover = 
                [[[UIPopoverController alloc] initWithContentViewController:picker] 
                 autorelease];
                self.photoPickerPopover.delegate = self;
                [self.photoPickerPopover 
                 presentPopoverFromBarButtonItem:sender 
                 permittedArrowDirections:UIPopoverArrowDirectionAny 
                 animated:YES];
            }
        }
    }
    else {
        [self presentModalViewController:picker animated:YES];
    }
}

#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker 
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self.photoPickerPopover dismissPopoverAnimated:YES];
    // The subclass implementation should do something with info.
}

#pragma mark UIPopoverControllerDelegate
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    self.photoPickerPopover = nil;
}

@end
