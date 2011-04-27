#import "FacebookMediaViewController.h"
#import "KGOSocialMediaController+FacebookAPI.h"
#import "FacebookUser.h"

#import "KGOFoursquareEngine.h"
#import "KGOTheme.h"

@implementation FacebookMediaViewController

@synthesize scrollView = _scrollView;
@synthesize photoPickerPopover;
@synthesize subheadToolbar;

#pragma mark -

- (IBAction)filterValueChanged:(UISegmentedControl *)sender {
    
    

}

- (IBAction)loginButtonPressed:(UIButton *)sender {
    [[KGOSocialMediaController sharedController] loginFacebook];
}

- (IBAction)uploadButtonPressed:(id)sender {
    DLog(@"uplaodButtonPressed should be overridden in a subclass.");
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
    [subheadToolbar release];
    [photoPickerPopover release];
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
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // Set up toolbar background.
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        UIImageView *backgroundView = 
        [[UIImageView alloc] initWithImage:
         [UIImage imageNamed:@"common/subheadbar_background"]];
        [self.subheadToolbar addSubview:backgroundView];
        [self.subheadToolbar sendSubviewToBack:backgroundView];
        [backgroundView release];
        
    // Set up segmented control images.
//    [_filterControl 
//     setImage:[UIImage imageNamed:@"common/toolbar-segmented-left"] 
//     forSegmentAtIndex:kAllMediaObjectsSegment];
//    [_filterControl 
//     setImage:[UIImage imageNamed:@"common/toolbar-segmented-middle"] 
//     forSegmentAtIndex:kMyUploadsSegment];
//    [_filterControl 
//     setImage:[UIImage imageNamed:@"common/toolbar-segmented-right"] 
//     forSegmentAtIndex:kBookmarksSegment];
    }
    
    if (facebookUserLoggedIn) {
        [self hideLoginViewAnimated:NO];
    }
    _loginHintLabel.text = NSLocalizedString(@"Photos and videos are posted to the Facebook group page for each class. To view and comment on them, you must sign into Facebook, and you must be a member of the class Facebook group.", nil);
    [_loginButton setTitle:@"Sign in to Facebook" forState:UIControlStateNormal];
    
    [pool release];
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
