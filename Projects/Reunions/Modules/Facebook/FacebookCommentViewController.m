
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import "FacebookCommentViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "KGOSocialMediaController+FacebookAPI.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "KGOTheme.h"
#import "Foundation+KGOAdditions.h"
#import "AnalyticsWrapper.h"
#import "FacebookModel.h"

@implementation FacebookCommentViewController

@synthesize profileID, post, delegate;
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
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark -

- (IBAction)submitButtonPressed:(id)sender {
    NSAssert(self.post != nil || self.profileID != nil, @"no post or profile id provided");
    
    if (self.post) {
        [[KGOSocialMediaController facebookService] addComment:_textView.text toFacebookPost:self.post delegate:self.delegate];
    } else if (self.profileID) {
        [[KGOSocialMediaController facebookService] postStatus:_textView.text toProfile:self.profileID delegate:self.delegate];
    }
    
    _loadingViewContainer.hidden = NO;
    [_spinner startAnimating];
    
    NSString *action = nil;
    NSString *label = nil;
    if (self.profileID) {
        action = @"Facebook Post";
        label = self.profileID;
        
    } else {
        action = @"Facebook Comment";
        label = self.post.identifier;
    }
    
    [[AnalyticsWrapper sharedWrapper] trackGroupAction:action label:label];
}

- (IBAction)cancelButtonPressed:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.post) {
        self.title = @"Comment";
    } else if (self.profileID) {
        self.title = @"Post";
    }
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                            target:self
                                                                                            action:@selector(submitButtonPressed:)] autorelease];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                           target:self
                                                                                           action:@selector(cancelButtonPressed:)] autorelease];
    
    _textView.layer.cornerRadius = 5.0;
    _textView.layer.borderColor = [[UIColor blackColor] CGColor];
    _textView.layer.borderWidth = 1.0;
    _textView.textColor = [UIColor grayColor];    
    [_textView becomeFirstResponder];
    
    _textEditBegun = NO;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if (!_textEditBegun) {
        _textView.textColor = [UIColor blackColor];
        _textView.text = @"";
        _textEditBegun = YES;
    }
}

- (void)textViewDidChange:(UITextView *)textView
{
    self.navigationItem.rightBarButtonItem.enabled = _textView.text.length > 0;
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
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    } else {
        return (interfaceOrientation == UIInterfaceOrientationPortrait);
    }
}

#pragma mark UITextView

@end
