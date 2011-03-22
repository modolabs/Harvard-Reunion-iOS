//
//  CustomBumpUI
//  Universitas
//
//  Created by Jim Kang on 3/22/11.
//  Copyright 2011 Modo Labs. All rights reserved.
//

#import "CustomBumpUI.h"

typedef enum
{
    kBumpUIGenericAlertTag = 0x105
}
CustomBumpUITags;

#pragma mark Private methods

@interface CustomBumpUI (Private)

- (void)showAlert:(NSString *)message;

@end

@implementation CustomBumpUI (Private)

- (void)showAlert:(NSString *)message
{
    UIAlertView *alertView = 
    [[UIAlertView alloc]
     initWithTitle:nil message:message 
     delegate:nil 
     cancelButtonTitle:nil 
     otherButtonTitles:@"OK", nil];
    alertView.tag = kBumpUIGenericAlertTag;
    [alertView show];
    [alertView release];
}

@end



@implementation CustomBumpUI

#pragma mark BumpAPICustomUI


/**
 * Result of requestSession on BumpAPI (user wants to connect to another device via Bump). UI should
 * now first appear saying something like "Warming up".
 */
- (void)bumpRequestSessionCalled
{
    [self showAlert:@"bumpRequestSessionCalled"];
}

/**
 * We were unable to establish a connection to the Bump network. Either show an error message or
 * hide the popup. The BumpAPIDelegate is about to be called with bumpSessionFailedToStart.
 */
- (void)bumpFailedToConnectToBumpNetwork
{
    [self showAlert:@"bumpFailedToConnectToBumpNetwork"];
}

/**
 * We were able to establish a connection to the Bump network and you are now ready to bump. 
 * The UI should say something like "Ready to Bump".
 */
- (void)bumpConnectedToBumpNetwork
{
    [self showAlert:@"bumpFailedToConnectToBumpNetwork"];
}

/**
 * Result of endSession call on BumpAPI. Will soon be followed by the call to bumpSessionEnded: on
 * API delegate. Highly unlikely to happen while the custom UI is up, but provided as a convenience
 * just in case.
 */
- (void)bumpEndSessionCalled
{
    [self showAlert:@"bumpEndSessionCalled"];
}

/**
 * Once the intial connection to the bump network has been made, there is a chance the connection
 * to the Bump Network is severed. In this case the bump network might come back, so it's
 * best to put the user back in the warming up state. If this happens too often then you can 
 * provide extra messaging and/or explicitly call endSession on the BumpAPI.
 */
- (void)bumpNetworkLost
{
    [self showAlert:@"bumpNetworkLost"];
}

/**
 * Physical bump occurced. Update UI to tell user that a bump has occured and the Bump System is
 * trying to figure out who it matched with.
 */
- (void)bumpOccurred
{
    [self showAlert:@"bumpOccurred"];
}

/**
 * Let's you know that a match could not be made via a bump. It's best to prompt users to try again.
 * @param		reason			Why the match failed
 */
- (void)bumpMatchFailedReason:(BumpMatchFailedReason)reason
{
    [self showAlert:[NSString stringWithFormat:
                     @"bumpFailedToConnectToBumpNetwork reason: %d", reason]];
}

/**
 * The user should be presented with some data about who they matched, and whether they want to
 * accept this connection. (Pressing Yes/No should call confirmMatch:(BOOL) on the BumpAPI).
 * param		bumper			Information about the device the bump system mached with
 */
- (void)bumpMatched:(Bumper*)bumper
{
    UIAlertView *alertView = 
    [[UIAlertView alloc] 
     initWithTitle:@"Connection made"
     message:[NSString stringWithFormat:@"Do you want to connect with %@?", 
              [bumper userName]] 
     delegate:self 
     cancelButtonTitle:@"Cancel" 
     otherButtonTitles:@"Connect", nil];
    [alertView show];
}

/**
 * Called after both parties have pressed yes, and bumpSessionStartedWith:(Bumper) is about to be 
 * called on the API Delegate. You should now close the matching UI.
 */
- (void)bumpSessionStarted
{
    [self showAlert:@"bumpFailedToConnectToBumpNetwork"];
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) 
    {
        case 0: 
            // Cancelled.
            [[BumpAPI sharedInstance] confirmMatch:NO];
            break;
        default:
            // Said yes to connect.
            [[BumpAPI sharedInstance] confirmMatch:YES];
            break;
    }
}

@end
