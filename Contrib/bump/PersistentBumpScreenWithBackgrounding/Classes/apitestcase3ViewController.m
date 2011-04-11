//
//  apitestcase3ViewController.m
//  apitestcase3
//
//  Copyrights / Disclaimer
//  Copyright 2011, Bump Technologies, Inc. All rights reserved.
//  Use of the software programs described herein is subject to applicable
//  license agreements and nondisclosure agreements. Unless specifically
//  otherwise agreed in writing, all rights, title, and interest to this
//  software and documentation remain with Bump Technologies, Inc. Unless
//  expressly agreed in a signed license agreement, Bump Technologies makes
//  no representations about the suitability of this software for any purpose
//  and it is provided "as is" without express or implied warranty.
//
//  Copyright (c) 2011 Bump Technologies Inc. All rights reserved.

#import "apitestcase3ViewController.h"

@implementation apitestcase3ViewController



/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	BumpAPI *api = [BumpAPI sharedInstance];
	[api configAPIKey:@"2ab8b00944d542d4b12544265d9f3dba"];
	[api configUIDelegate:self];
	[api configDelegate:self];
	[api requestSession];
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

- (IBAction)simBumpPressed:(id)sender {
	[[BumpAPI sharedInstance] simulateBump];
}

/**
 * Result of requestSession on BumpAPI (user wants to connect to another device via Bump). UI should
 * now first appear saying something like "Warming up".
 */
-(void)bumpRequestSessionCalled {
	[_label setText:@"Request Session Called... Warming up"];
}

/**
 * We were unable to establish a connection to the Bump network. Either show an error message or
 * hide the popup. The BumpAPIDelegate is about to be called with bumpSessionFailedToStart.
 */
-(void)bumpFailedToConnectToBumpNetwork {
	[_label setText:@"Failed to connect... retrying"];
	[[BumpAPI sharedInstance] requestSession];
}

/**
 * We were able to establish a connection to the Bump network and you are now ready to bump. 
 * The UI should say something like "Ready to Bump".
 */
-(void)bumpConnectedToBumpNetwork {
	[_label setText:@"Ready to Bump"];
}

/**
 * Result of endSession call on BumpAPI. Will soon be followed by the call to bumpSessionEnded: on
 * API delegate. Highly unlikely to happen while the custom UI is up, but provided as a convenience
 * just in case.
 */
-(void)bumpEndSessionCalled {
	[_label	 setText:@"End Session was called"];
	NSLog(@"UI Callback, end session called");
}

/**
 * Once the intial connection to the bump network has been made, there is a chance the connection
 * to the Bump Network is severed. In this case the bump network might come back, so it's
 * best to put the user back in the warming up state. If this happens too often then you can 
 * provide extra messaging and/or explicitly call endSession on the BumpAPI.
 */
-(void)bumpNetworkLost {
	[_label setText:@"Warming up... network was lost"];
}

/**
 * Physical bump occurced. Update UI to tell user that a bump has occured and the Bump System is
 * trying to figure out who it matched with.
 */
-(void)bumpOccurred {
	[_label setText:@"Bumped! Trying to connecect..."];
}

/**
 * Let's you know that a match could not be made via a bump. It's best to prompt users to try again.
 * @param		reason			Why the match failed
 */
-(void)bumpMatchFailedReason:(BumpMatchFailedReason)reason {
	[_label setText:@"Match failed, try again"];
}

/**
 * The user should be presented with some data about who they matched, and whether they want to
 * accept this connection. (Pressing Yes/No should call confirmMatch:(BOOL) on the BumpAPI).
 * param		bumper			Information about the device the bump system mached with
 */
-(void)bumpMatched:(Bumper*)bumper {
	[_label setText:@"Matched! about to start..."];
	[[BumpAPI sharedInstance] confirmMatch:YES];
}

/**
 * Called after both parties have pressed yes, and bumpSessionStartedWith:(Bumper) is about to be 
 * called on the API Delegate. You should now close the matching UI.
 */
-(void)bumpSessionStarted {
	[_label setText:@"Session started!!!"];
}


#pragma mark *********************** API Delegate

/**
 Successfully started a Bump session with another device.
 @param		otherBumper		Let's you know how the other device identifies itself
 Can also be accessed later via the otherBumper method on the API
 */
- (void) bumpSessionStartedWith:(Bumper *)otherBumper {
	//Start sending data
	//call end session when you're done sending stuff you want
}

/**
 There was an error while trying to start the session these reasons are helpful and let you know
 what's going on
 @param		reason			Why the session failed to start
 */
- (void) bumpSessionFailedToStart:(BumpSessionStartFailedReason)reason {
	
}

/**
 The bump session was ended, reason tells you wheter it was expected or not
 @param		reason			Why the session ended. Could be either expected or unexpected.
 */
- (void) bumpSessionEnded:(BumpSessionEndReason)reason {
	[_label setText:@"Bump session ended"];
	NSLog(@"Session has ended, requesting a new one");
	[[BumpAPI sharedInstance] requestSession];//auto request a new session since we always want
											  //to be doing something
}

/**
 The symmetrical call to sendData on the API. When the other device conneced via Bump calls sendData
 this device get's this call back
 @param		reason			Data sent by the other device.
 */
- (void) bumpDataReceived:(NSData *)chunk {
	//start recieving data
}


@end
