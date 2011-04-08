//
//  ConnectViewController.m
//  Universitas
//
//  Created by Jim Kang on 3/22/11.
//  Copyright 2011 Modo Labs. All rights reserved.
//

#import "ConnectViewController.h"
#import "BumpAPI.h"
#import "AddressBookUtils.h"

typedef enum
{
    kBumpIncomingLabel = 0x324
}
ConnectViewControllerTags;



#pragma mark Private methods

@interface ConnectViewController (Private)

- (void)setUpBump;

#pragma mark Address book
- (void)showPicker;
- (void)addAddressBookRecordForDict:(NSDictionary *)serializedRecord;
- (void)promptAboutAddingIncomingRecord;

@end

@implementation ConnectViewController (Private)

- (void)setUpBump
{
    BumpAPI *bumpObject = [BumpAPI sharedInstance];        
//    [self.customBumpUI setParentView:self.view];
//    [self.customBumpUI setBumpAPIObject:[BumpAPI sharedInstance]];
    [[BumpAPI sharedInstance] configUIDelegate:self.customBumpUI];
    
    // Start Bump.
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
    
    [self presentModalViewController:picker animated:YES];
    [picker release];    
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
        [NSString stringWithFormat:@"Do you want to add %@ %@ to your Contacts?",
         [self.incomingABRecordDict objectForKey:@"kABPersonFirstNameProperty"],
         [self.incomingABRecordDict objectForKey:@"kABPersonLastNameProperty"]];
        
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

@end


@implementation ConnectViewController

@synthesize customBumpUI;
@synthesize incomingABRecordDict;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)init
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.customBumpUI = [[[CustomBumpUI alloc] init] autorelease];
    }
    return self;
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
    [super loadView];
    //self.view.backgroundColor = [UIColor greenColor];
        
    UILabel *incomingLabel = [[UILabel alloc] initWithFrame:
                              CGRectMake(20, 140, 280, 80)];
    incomingLabel.tag = kBumpIncomingLabel;
    [self.view addSubview:incomingLabel];
    [incomingLabel release];
        
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
    [[BumpAPI sharedInstance] configUIDelegate:nil];
    [[BumpAPI sharedInstance] endSession];
    
    [customBumpUI release];
    [incomingABRecordDict release];
    
    [super dealloc];
}

#pragma mark BumpAPIDelegate methods

- (void)bumpDataReceived:(NSData *)chunk {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	// The chunk sent from the other user is a dictionary representing an ABRecord. 
    self.incomingABRecordDict = [NSKeyedUnarchiver unarchiveObjectWithData:chunk];
    
    // Update label with incoming text.
    UILabel *incomingLabel = (UILabel *)[self.view viewWithTag:kBumpIncomingLabel];
    incomingLabel.text = 
    [self.incomingABRecordDict objectForKey:@"kABPersonOrganizationProperty"];
    
    if (addressBookPickerShowing) {
        shouldPromptAboutAddingRecordAtNextChance = YES;
    }
    else {
        [self promptAboutAddingIncomingRecord];
    }    
    
    [pool release];
}

- (void)bumpSessionStartedWith:(Bumper*)otherBumper{
    NSLog(@"Bump session started.");
    [self showPicker];
}

- (void)bumpSessionEnded:(BumpSessionEndReason)reason {
	NSString *alertText;
	switch (reason) {
		case END_OTHER_USER_QUIT:
			alertText = @"Other user has quit the session.";
			break;
		case END_LOST_NET:
			alertText = @"Connection to Bump server was lost.";
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
	
	if(reason != END_USER_QUIT){ 
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Disconnected" message:alertText delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
}

- (void)bumpSessionFailedToStart:(BumpSessionStartFailedReason)reason {
	
	NSString *alertText;
	switch (reason) {
		case FAIL_NETWORK_UNAVAILABLE:
			alertText = @"Please check your network settings and try again.";
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
	
	if(reason != FAIL_USER_CANCELED){
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
    [self dismissModalViewControllerAnimated:YES];
}

- (BOOL)peoplePickerNavigationController:
(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person {
        
    [self dismissModalViewControllerAnimated:YES];
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
    if (buttonIndex == 0) {
        [self addAddressBookRecordForDict:self.incomingABRecordDict];
    }
    self.incomingABRecordDict = nil;
}

@end
