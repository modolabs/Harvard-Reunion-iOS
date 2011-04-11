//
//  ConnectViewController.h
//

#import <UIKit/UIKit.h>
#import "BumpAPI.h"
#import "BumpAPICustomUI.h"
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@interface ConnectViewController : UIViewController <BumpAPIDelegate, 
UITextFieldDelegate, ABPeoplePickerNavigationControllerDelegate,
UIAlertViewDelegate, BumpAPICustomUI> {
    BOOL shouldPromptAboutAddingRecordAtNextChance;
    BOOL addressBookPickerShowing;
}

@property (nonatomic, retain) NSDictionary *incomingABRecordDict;
@property (nonatomic, retain) UIActivityIndicatorView *spinner;
// The current state of the Bump connection.
@property (nonatomic, retain) UILabel *statusLabel;
// The most recent notification about the Bump connection.
@property (nonatomic, retain) UILabel *messageLabel;

@end
