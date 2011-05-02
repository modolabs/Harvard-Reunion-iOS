#import "PhotoUploadViewController.h"
#import "KGOSocialMediaController+FacebookAPI.h"
#import "FacebookPhotosViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "KGOAppDelegate.h"
#import "UIKit+KGOAdditions.h"
#import "AnalyticsWrapper.h"

@implementation FacebookPhotoCaptionViewController

@synthesize parentVC;

- (void)viewDidLoad
{
    [super viewDidLoad];

    _textView.text = self.parentVC.caption;
    _textView.textColor = [UIColor darkTextColor];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    // don't adopt parent's behavior which erases the text
}

- (IBAction)submitButtonPressed:(id)sender
{
    self.parentVC.caption = _textView.text;
    [self.parentVC dismissModalViewControllerAnimated:YES];
}

@end



@implementation PhotoUploadViewController

@synthesize photo, profile, parentVC, captionButton = _captionButton;

- (NSString *)caption
{
    return _caption;
}

- (void)setCaption:(NSString *)caption
{
    [_caption release];
    _caption = [caption retain];
    
    if (_caption.length) {
        [_captionButton setTitle:_caption forState:UIControlStateNormal];
        [_captionButton setTitle:_caption forState:UIControlStateHighlighted];
        [_captionButton setTitleColor:[UIColor darkTextColor] forState:UIControlStateNormal];
        [_captionButton setTitleColor:[UIColor darkTextColor] forState:UIControlStateHighlighted];
    } else {
        [_captionButton setTitle:@"Add a caption..." forState:UIControlStateNormal];
        [_captionButton setTitle:@"Add a caption..." forState:UIControlStateHighlighted];
        [_captionButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [_captionButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    }
}

- (void)uploadButtonPressed:(id)sender
{
    _loadingView.hidden = NO;
    [_spinner startAnimating];

    [[KGOSocialMediaController facebookService] uploadPhoto:self.photo
                                          toFacebookProfile:self.profile
                                                    message:self.caption
                                                   delegate:self.parentVC];
    
    [[AnalyticsWrapper sharedWrapper] trackEvent:@"Facebook"
                                          action:@"Photo upload"
                                           label:[NSString stringWithFormat:@"facebook profile id: %@", self.profile]];
}

- (IBAction)captionButtonPressed:(UIButton *)sender {
    FacebookPhotoCaptionViewController *captionVC = [[[FacebookPhotoCaptionViewController alloc] initWithNibName:@"FacebookCommentViewController" bundle:nil] autorelease];
    captionVC.parentVC = self;
    UINavigationController *navC = [[[UINavigationController alloc] initWithRootViewController:captionVC] autorelease];
    navC.navigationBar.barStyle = UIBarStyleBlack;
    navC.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentModalViewController:navC animated:YES];
    
    captionVC.title = self.title;
}

- (void)cancelButtonPressed:(id)sender {
    [self.parentViewController dismissModalViewControllerAnimated:YES];
}

/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/

- (void)dealloc
{
    [_caption release];
    self.photo = nil;
    self.profile = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.title = @"Upload Photo";
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Upload"
                                                                               style:UIBarButtonItemStyleDone
                                                                              target:self
                                                                              action:@selector(uploadButtonPressed:)] autorelease];
    if (!self.navigationItem.leftBarButtonItem) {
        self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                               target:self
                                                                                               action:@selector(cancelButtonPressed:)] autorelease];
    }
    
    _captionButton.layer.cornerRadius = 5.0;
    _captionButton.layer.borderColor = [[UIColor blackColor] CGColor];
    _captionButton.layer.borderWidth = 1.0;
    
    [_captionButton setBackgroundImage:[UIImage imageWithPathName:@"common/textfield_button_background"] forState:UIControlStateNormal];
    
    self.caption = nil;
    
    _imageView.image = self.photo;
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
