
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import "FoursquareAddCheckinViewController.h"
#import "FoursquareCheckinViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "KGOAppDelegate.h"
#import "KGOTheme.h"
#import "Foundation+KGOAdditions.h"
#import "KGOSocialMediaController.h"
#import "KGOFoursquareEngine.h"
#import "AnalyticsWrapper.h"

@implementation FoursquareAddCheckinViewController

@synthesize shout, parent, venue;
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
    [[[KGOSocialMediaController foursquareService] foursquareEngine] checkinVenue:self.venue
                                                                         delegate:self.parent
                                                                          message:_textView.text];

    _loadingViewContainer.hidden = NO;
    [_spinner startAnimating];
    
    [[AnalyticsWrapper sharedWrapper] trackGroupAction:@"Foursquare Checkin" label:self.venue];
}

- (IBAction)cancelButtonPressed:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Check In";
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                            target:self
                                                                                            action:@selector(submitButtonPressed:)] autorelease];
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
    if(!_textEditBegun) {
        _textView.textColor = [UIColor blackColor];
        _textView.text = @"";
        _textEditBegun = YES;
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
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    } else {
        return (interfaceOrientation == UIInterfaceOrientationPortrait);
    }
}

#pragma mark UITextView

@end
