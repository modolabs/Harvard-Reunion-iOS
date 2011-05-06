#import "KGOShareButtonController.h"
#import "KGOAppDelegate.h"
#import "TwitterViewController.h"
#import "MITMailComposeController.h"
#import "AnalyticsWrapper.h"

@implementation KGOShareButtonController

@synthesize contentsController, shareTitle, shareURL, shareBody, actionSheetTitle;

- (id)initWithContentsController:(UIViewController *)aController {
    self = [super init];
    if (self) {
        self.contentsController = aController;
	}
	return self;
}

- (NSUInteger)shareTypes
{
    return _shareTypes;
}

- (void)setShareTypes:(NSUInteger)shareTypes
{
    if (_shareTypes != shareTypes) {
        _shareTypes = shareTypes;
        [_shareMethods release];
        _shareMethods = nil;
    }
}

- (void)shareInView:(UIView *)view {
    
    if (!_shareMethods) {
        NSMutableArray *methods = [NSMutableArray array];
        
        if (self.shareTypes | KGOShareControllerShareTypeEmail
            && [[KGOSocialMediaController sharedController] supportsEmailSharing]
        ) {
            [methods addObject:KGOSocialMediaTypeEmail];
        }
        
        if (self.shareTypes | KGOShareControllerShareTypeFacebook
            && [[KGOSocialMediaController sharedController] supportsFacebookSharing]
        ) {
            [methods addObject:KGOSocialMediaTypeFacebook];
        }
        
        if (self.shareTypes | KGOShareControllerShareTypeTwitter
            && [[KGOSocialMediaController sharedController] supportsTwitterSharing]
        ) {
            [methods addObject:KGOSocialMediaTypeTwitter];
        }
        
        _shareMethods = [methods copy];
    }

    if (_shareMethods.count > 1) {
        
        NSString *cancelTitle = nil;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            cancelTitle = NSLocalizedString(@"Cancel", @"share action sheet");
        }
        UIActionSheet *shareSheet = [[UIActionSheet alloc] initWithTitle:self.actionSheetTitle
                                                                delegate:self
                                                       cancelButtonTitle:cancelTitle
                                                  destructiveButtonTitle:nil
                                                       otherButtonTitles:nil];
        
        for (NSString *aMethod in _shareMethods) {
            [shareSheet addButtonWithTitle:[KGOSocialMediaController localizedNameForService:aMethod]];
        }
	
        [shareSheet showInView:view];
        [shareSheet release];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (buttonIndex == [actionSheet cancelButtonIndex]) {
            return;
        }
        if (buttonIndex > [actionSheet cancelButtonIndex]) {
            buttonIndex--;
        }
    }
    
    NSString *method = [_shareMethods objectAtIndex:buttonIndex];

	if ([method isEqualToString:KGOSocialMediaTypeEmail]) {
        // TODO: make this string configurable
        NSString *emailBody = [NSString stringWithFormat:
                               @"I thought you might be interested in this...\n\n%@\n\n%@", self.shareBody, self.shareURL];
        [self.contentsController presentMailControllerWithEmail:nil
                                                        subject:self.shareTitle
                                                           body:emailBody 
                                                       delegate:self];

	} else if ([method isEqualToString:KGOSocialMediaTypeFacebook]) {
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                self.shareTitle, @"name",
                                self.shareBody, @"description",
                                self.shareURL, @"link",
                                nil];
        
        [[KGOSocialMediaController facebookService] shareOnFacebook:params];
        
        // TODO: this can't record if the user taps cancel; the listener is in
        // KGOFacebookService
        [[AnalyticsWrapper sharedWrapper] trackGroupAction:@"Facebook Share" label:self.shareURL];

	} else if ([method isEqualToString:KGOSocialMediaTypeTwitter]) {
		TwitterViewController *twitterVC = [[[TwitterViewController alloc] initWithNibName:@"TwitterViewController"
                                                                                    bundle:nil] autorelease];
        twitterVC.preCannedMessage = self.shareTitle;
        twitterVC.longURL = self.shareURL;
        twitterVC.delegate = self;
        
        UINavigationController *navC = [[[UINavigationController alloc] initWithRootViewController:twitterVC] autorelease];
        navC.modalPresentationStyle = UIModalPresentationFormSheet;
        
		[self.contentsController presentModalViewController:navC animated:YES];
	}
}

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error 
{
    [self.contentsController dismissModalViewControllerAnimated:YES];
    
    [[AnalyticsWrapper sharedWrapper] trackGroupAction:@"Email Share" label:self.shareURL];
}


#pragma mark TwitterViewControllerDelegate

- (BOOL)controllerShouldContinueToMessageScreen:(TwitterViewController *)controller
{
    return YES;
}

- (void)controllerDidPostTweet:(TwitterViewController *)controller
{
    [self.contentsController dismissModalViewControllerAnimated:YES];

    // will do nothing if no analytics provider is configured
    [[AnalyticsWrapper sharedWrapper] trackGroupAction:@"Twitter Share" label:self.shareURL];
}

- (void)controllerFailedToTweet:(TwitterViewController *)controller
{
    [self.contentsController dismissModalViewControllerAnimated:YES];

    // record the attempt.
    // will do nothing if no analytics provider is configured
    [[AnalyticsWrapper sharedWrapper] trackGroupAction:@"Twitter Share" label:self.shareURL];
}

#pragma mark -

- (void)dealloc {
    self.contentsController = nil;
    
    self.shareTitle = nil;
    self.actionSheetTitle = nil;
    self.shareBody = nil;
    self.shareURL = nil;
    [_shareMethods release];
    _shareMethods = nil;

    [super dealloc];
}


@end
