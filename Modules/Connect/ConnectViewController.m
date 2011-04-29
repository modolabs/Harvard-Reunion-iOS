//
//  ConnectViewController.m
//

#import "ConnectViewController.h"
#import "BumpAPI.h"
#import "AddressBookUtils.h"
#import "KGOTheme.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "UIKit+KGOAdditions.h"

typedef enum
{
    kBumpStatusLabel = 0x324,
    kBumpMessageLabel,
    kBumpSpinnerView,
    kBumpUIGenericAlertTag,
    kBumpConnectRequestAlertTag
}
CustomBumpUITags;

#define kBumpStatusConnecting @"Getting ready to share contact info..."
#define kBumpStatusConnectedToNetwork @"To share contact info with a friend, "\
"bump your devices gently together."
#define kBumpStatusDisconnected @"Not connected to the Bump network."
#define kBumpStatusConnectedToPerson @"Connected to another person."

static const CGFloat kConnectViewSubviewMargin = 20.0f;

#pragma mark Private methods

@interface ConnectViewController (Private)

- (void)setUpBump;

#pragma mark Address book
- (void)showPicker;
- (UIViewController *)peoplePickerOwner;
- (void)addAddressBookRecordForDict:(NSDictionary *)serializedRecord;
- (void)promptAboutAddingIncomingRecord;
+ (NSString *)nameFromAddressBookDict:(NSDictionary *)serializedRecord;

#pragma mark Bump UI
- (void)showAlert:(NSString *)message;

// status: The current state of the Bump connection.
// message: The most recent notification about the Bump connection.
// Making either of them nil will leave them unchanged.
- (void)updateStatus:(NSString *)status andMessage:(NSString *)message;

@end

@implementation ConnectViewController (Private)

- (void)setUpBump {
    BumpAPI *bumpObject = [BumpAPI sharedInstance];        
    [bumpObject configUIDelegate:self];
    [bumpObject configAPIKey:@"57571df95089489d906d0d396ace290d"];
    [bumpObject configDelegate:self];
    [bumpObject configParentView:self.view];
    [bumpObject configActionMessage:
     @"Bump with another app user to get started."];
    [bumpObject requestSession];
}

#pragma mark Address book
- (void)showPicker {
    addressBookPickerShowing = YES;
    ABPeoplePickerNavigationController *picker =
    [[ABPeoplePickerNavigationController alloc] init];    
    picker.peoplePickerDelegate = self;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {    
        picker.modalPresentationStyle = UIModalPresentationFormSheet;        
    }    
    [[self peoplePickerOwner] presentModalViewController:picker animated:YES];
    picker.navigationBar.topItem.prompt = @"Select a contact to share";
    [picker release];    
}

- (UIViewController *)peoplePickerOwner {
    UIViewController *peoplePickerOwner = self;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        peoplePickerOwner = 
        ((KGOAppDelegate *)KGO_SHARED_APP_DELEGATE()).visibleViewController;
    }
    return peoplePickerOwner;
}

- (void)addAddressBookRecordForDict:(NSDictionary *)serializedRecord {
    ABAddressBookRef addressBook = ABAddressBookCreate();
    
    ABRecordRef newRecord = ABPersonCreate();    
    [AddressBookUtils setUpABRecord:newRecord withDict:serializedRecord];
    
    CFErrorRef error = NULL;
    if (!ABAddressBookAddRecord(addressBook, newRecord, &error)) {
        NSLog(@"Error adding record to address book.");
    }
    
    error = NULL;
    if (!ABAddressBookSave(addressBook, &error)) {
        NSLog(@"Error saving to address book.");
    }
    
    CFRelease(newRecord);
    CFRelease(addressBook);
}

- (void)promptAboutAddingIncomingRecord
{
    // Ask about adding person sent to us to address book.
    if (self.incomingABRecordDict) {
        NSString *alertQuestion = 
        [NSString stringWithFormat:@"Do you want to add %@ to your Contacts?",
         [[self class] nameFromAddressBookDict:self.incomingABRecordDict]];
        
        UIAlertView *alert = 
        [[UIAlertView alloc]
         initWithTitle:@"Add to Contacts" message:alertQuestion delegate:self 
         cancelButtonTitle:nil otherButtonTitles:@"Yes", @"No", nil];
        [alert show];
        [alert release];
        shouldPromptAboutAddingRecordAtNextChance = NO;
    }
    else {
        // Can't do it yet.
        shouldPromptAboutAddingRecordAtNextChance = YES;
    }
}

+ (NSString *)nameFromAddressBookDict:(NSDictionary *)serializedRecord {
    return [NSString stringWithFormat:@"%@ %@",
            [serializedRecord objectForKey:@"kABPersonFirstNameProperty"],
            [serializedRecord objectForKey:@"kABPersonLastNameProperty"]];    
}

#pragma mark Bump UI
- (void)showAlert:(NSString *)message
{
    UIAlertView *alertView = 
    [[UIAlertView alloc]
     initWithTitle:nil 
     message:message 
     delegate:nil 
     cancelButtonTitle:nil 
     otherButtonTitles:@"OK", nil];
    alertView.tag = kBumpUIGenericAlertTag;
    [alertView show];
    [alertView release];
}

- (void)updateStatus:(NSString *)status andMessage:(NSString *)message {
    if (status) {
        self.statusLabel.text = status;
        
        if ([status isEqualToString:kBumpStatusConnecting]) {
            [self.spinner startAnimating];
        }
        else {
            [self.spinner stopAnimating];
        }
    }
    if (message) {
        self.messageLabel.text = message;
    }
}

@end


@implementation ConnectViewController

@synthesize incomingABRecordDict;
@synthesize statusLabel;
@synthesize messageLabel;
@synthesize spinner;
@synthesize demoImageView;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)init
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.navigationItem.title = @"Connect";
    }
    return self;
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
    [super loadView];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    self.view.autoresizingMask = 
    UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    CGFloat viewWidth = self.view.frame.size.width;
    
    UIView *backgroundView = [[[UIView alloc] initWithFrame:self.view.bounds] autorelease];
    backgroundView.backgroundColor = [UIColor whiteColor];
    backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        backgroundView.frame = CGRectMake(0, 49, self.view.bounds.size.width, self.view.bounds.size.height - 51);
    }
    [self.view addSubview:backgroundView];
            
    self.statusLabel = 
    [[[UILabel alloc] initWithFrame:
      CGRectMake(kConnectViewSubviewMargin, 
                 12, 
                 viewWidth - 2 * kConnectViewSubviewMargin, 
                 80)] 
     autorelease];
    self.statusLabel.textAlignment = UITextAlignmentCenter;
    self.statusLabel.tag = kBumpStatusLabel;
    self.statusLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    self.statusLabel.backgroundColor = [UIColor clearColor];
    
    UIFont *font = [[KGOTheme sharedTheme] defaultFont];
    self.statusLabel.font = font;
    self.statusLabel.numberOfLines = 0;
    [backgroundView addSubview:self.statusLabel];

    self.spinner = 
    [[[UIActivityIndicatorView alloc] 
      initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge]
     autorelease];
    CGRect spinnerFrame = self.spinner.frame;
    spinnerFrame.origin.x = viewWidth/2;
    spinnerFrame.origin.y = 210; 
    self.spinner.frame = spinnerFrame;
    self.spinner.autoresizingMask = 
    UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;    
    [backgroundView addSubview:self.spinner];
    
    self.demoImageView = [[[UIImageView alloc] initWithImage:[UIImage imageWithPathName:@"modules/bump/bumping"]] autorelease];
    [backgroundView addSubview:self.demoImageView];
    self.demoImageView.center = backgroundView.center;
    self.demoImageView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    self.demoImageView.hidden = YES;
    
    self.messageLabel = 
    [[[UILabel alloc] initWithFrame:
      CGRectMake(kConnectViewSubviewMargin, 
                 backgroundView.frame.size.height - 120, 
                 viewWidth - 2 * kConnectViewSubviewMargin, 
                 80)] autorelease];    
    self.messageLabel.tag = kBumpMessageLabel;
    self.messageLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    self.messageLabel.backgroundColor = [UIColor clearColor];
    self.messageLabel.font = font;
    self.messageLabel.numberOfLines = 0;
    self.messageLabel.textColor = [UIColor colorWithWhite:0.4 alpha:1];
    self.messageLabel.textAlignment = UITextAlignmentCenter;
    [self.view addSubview:self.messageLabel];

    UIImageView *imageView = [[[UIImageView alloc] initWithImage:[UIImage imageWithPathName:@"modules/bump/bump-logo"]] autorelease];
    CGRect frame = imageView.frame;
    frame.origin.x = floor((viewWidth - imageView.frame.size.width) / 2);
    frame.origin.y = backgroundView.bounds.size.height - imageView.frame.size.height - 10;
    imageView.frame = frame;
    imageView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    [backgroundView addSubview:imageView];

    UILabel *poweredByLabel = [UILabel multilineLabelWithText:@"Powered By" font:[UIFont systemFontOfSize:13] width:100];
    poweredByLabel.textAlignment = UITextAlignmentCenter;
    poweredByLabel.textColor = [UIColor colorWithWhite:0.4 alpha:1];
    poweredByLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    frame = poweredByLabel.frame;
    frame.origin.x = floor((viewWidth - frame.size.width) / 2);
    frame.origin.y = imageView.frame.origin.y - frame.size.height - 4;
    poweredByLabel.frame = frame;
    [backgroundView addSubview:poweredByLabel];
        
    [self setUpBump];
}

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    // Stop bump.
    [[BumpAPI sharedInstance] endSession];
    
    [spinner release];
    [messageLabel release];
    [statusLabel release];
    [incomingABRecordDict release];
    [demoImageView release];
    
    [super dealloc];
}

#pragma mark BumpAPIDelegate methods

- (void)bumpDataReceived:(NSData *)chunk {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
	// The chunk sent from the other user is a dictionary representing an ABRecord. 
    self.incomingABRecordDict = [NSKeyedUnarchiver unarchiveObjectWithData:chunk];
        
    if (addressBookPickerShowing) {
        shouldPromptAboutAddingRecordAtNextChance = YES;
    }
    else {
        [self promptAboutAddingIncomingRecord];
    }    
    [self updateStatus:nil andMessage:
     [NSString stringWithFormat:@"Received %@'s contact info!",
      [[self class] nameFromAddressBookDict:self.incomingABRecordDict]]];
    
    [pool release];
}

- (void)bumpSessionStartedWith:(Bumper*)otherBumper{
    NSLog(@"Bump session started.");
//    [self showPicker];
}

- (void)bumpSessionEnded:(BumpSessionEndReason)reason {
	NSString *alertText;
	switch (reason) {
		case END_OTHER_USER_QUIT:
			alertText = @"Other user has quit the session.";            
			break;
		case END_LOST_NET:
			alertText = @"Connection to Bump network was lost.";
			break;
		case END_OTHER_USER_LOST:
			alertText = @"Connection to other user was lost.";
			break;
		case END_USER_QUIT:
			alertText = @"You have been disconnected.";
			break;
		default:
			alertText = @"You have been disconnected.";
			break;
	}
    
    [self updateStatus:kBumpStatusDisconnected andMessage:alertText];
	
	if (reason != END_USER_QUIT) { 
		UIAlertView *alert = 
        [[UIAlertView alloc] 
         initWithTitle:@"Disconnected" 
         message:alertText 
         delegate:nil 
         cancelButtonTitle:@"OK" 
         otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
    
    // Start the session over.
    [self setUpBump];    
}

- (void)bumpSessionFailedToStart:(BumpSessionStartFailedReason)reason {
	
	NSString *alertText;
	switch (reason) {
		case FAIL_NETWORK_UNAVAILABLE:
			alertText = @"Please check your network settings and try again.";
            [self updateStatus:kBumpStatusDisconnected andMessage:alertText];
			break;
		case FAIL_INVALID_AUTHORIZATION:
			//the user should never see this, since we'll pass in the correct API auth strings.
			//just for debug.
			alertText = @"Failed to connect to the Bump service. Auth error.";
			break;
		default:
			alertText = @"Failed to connect to the Bump service.";
			break;
	}

    [self updateStatus:kBumpStatusDisconnected andMessage:alertText];
	
	if (reason != FAIL_USER_CANCELED) {
		//if the user canceled they know it and they don't need a popup.
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection Failed" message:alertText delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
}

#pragma mark UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark UI Actions

#pragma mark ABPeoplePickerNavigationControllerDelegate
- (void)peoplePickerNavigationControllerDidCancel:
(ABPeoplePickerNavigationController *)peoplePicker {
    [[self peoplePickerOwner] dismissModalViewControllerAnimated:YES];
}

- (BOOL)peoplePickerNavigationController:
(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person {
        
    [[self peoplePickerOwner] dismissModalViewControllerAnimated:YES];
    addressBookPickerShowing = NO;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // Send selected person.    
    NSDictionary *personDict = [AddressBookUtils dictionaryForRecord:person];
    NSData *chunk = [NSKeyedArchiver archivedDataWithRootObject:personDict];
    
    [[BumpAPI sharedInstance] sendData:chunk];
    
    if (shouldPromptAboutAddingRecordAtNextChance) {
        [self promptAboutAddingIncomingRecord];
    }

    [pool release];
    
    return NO;
}

- (BOOL)peoplePickerNavigationController:
(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
                                property:(ABPropertyID)property
                              identifier:(ABMultiValueIdentifier)identifier{
    return NO;
}


#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == kBumpConnectRequestAlertTag) {
        switch (buttonIndex) {
            case 0: 
                // Cancelled.
                [[BumpAPI sharedInstance] confirmMatch:NO];                
                break;
            default:
                // Said yes to connect.
                [[BumpAPI sharedInstance] confirmMatch:YES];
                [self showPicker];
                break;
        }
    }
    else {
        // Response to alert asking whether or not to add address to address book.        
        if (buttonIndex == 0) {
            [self addAddressBookRecordForDict:self.incomingABRecordDict];
            [self updateStatus:nil andMessage:
             [NSString stringWithFormat:@"Added %@ to contacts.",
              [[self class] nameFromAddressBookDict:self.incomingABRecordDict]]];
        }
        self.incomingABRecordDict = nil;
        
        // Start session over.
        [[BumpAPI sharedInstance] endSession];
        [self setUpBump];        
    }
}


#pragma mark BumpAPICustomUI


/**
 * Result of requestSession on BumpAPI (user wants to connect to another device via Bump). UI should
 * now first appear saying something like "Warming up".
 */
- (void)bumpRequestSessionCalled
{
    [self updateStatus:kBumpStatusConnecting andMessage:@""];
}

/**
 * We were unable to establish a connection to the Bump network. Either show an error message or
 * hide the popup. The BumpAPIDelegate is about to be called with bumpSessionFailedToStart.
 */
- (void)bumpFailedToConnectToBumpNetwork
{
    [self updateStatus:kBumpStatusDisconnected 
            andMessage:@"Failed to connect to the Bump network."];
}

/**
 * We were able to establish a connection to the Bump network and you are now ready to bump. 
 * The UI should say something like "Ready to Bump".
 */
- (void)bumpConnectedToBumpNetwork
{
    [self updateStatus:kBumpStatusConnectedToNetwork
            andMessage:@"Both you and your friend need to be running the Harvard Reunion app, open to this screen."];

    self.demoImageView.hidden = NO;
}

/**
 * Result of endSession call on BumpAPI. Will soon be followed by the call to bumpSessionEnded: on
 * API delegate. Highly unlikely to happen while the custom UI is up, but provided as a convenience
 * just in case.
 */
- (void)bumpEndSessionCalled
{
    [self updateStatus:kBumpStatusDisconnected andMessage:@""];
}

/**
 * Once the intial connection to the bump network has been made, there is a chance the connection
 * to the Bump Network is severed. In this case the bump network might come back, so it's
 * best to put the user back in the warming up state. If this happens too often then you can 
 * provide extra messaging and/or explicitly call endSession on the BumpAPI.
 */
- (void)bumpNetworkLost
{
    [self updateStatus:kBumpStatusDisconnected 
            andMessage:@"Lost connection to the Bump network."];
}

/**
 * Physical bump occurced. Update UI to tell user that a bump has occured and the Bump System is
 * trying to figure out who it matched with.
 */
- (void)bumpOccurred
{
    [self updateStatus:nil andMessage:@"Bumped!"];
}

/**
 * Let's you know that a match could not be made via a bump. It's best to prompt users to try again.
 * @param		reason			Why the match failed
 */
- (void)bumpMatchFailedReason:(BumpMatchFailedReason)reason
{
    [self updateStatus:nil andMessage:@"Could not make a Bump match."];
}

/**
 * The user should be presented with some data about who they matched, and whether they want to
 * accept this connection. (Pressing Yes/No should call confirmMatch:(BOOL) on the BumpAPI).
 * param		bumper			Information about the device the bump system mached with
 */
- (void)bumpMatched:(Bumper*)bumper
{
    NSString *message = [NSString stringWithFormat:
                         @"Do you want to connect with %@?", 
                         [bumper userName]];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Connection made"
                                                        message:message
                                                       delegate:self 
                                              cancelButtonTitle:@"Cancel" 
                                              otherButtonTitles:@"Connect", nil];
    alertView.tag = kBumpConnectRequestAlertTag;
    [alertView show];
    [alertView release];
    [self updateStatus:kBumpStatusConnectedToPerson andMessage:nil];
}

/**
 * Called after both parties have pressed yes, and bumpSessionStartedWith:(Bumper) is about to be 
 * called on the API Delegate. You should now close the matching UI.
 */
- (void)bumpSessionStarted
{
    [self updateStatus:kBumpStatusConnectedToPerson andMessage:@"Connected!"];
}


@end
