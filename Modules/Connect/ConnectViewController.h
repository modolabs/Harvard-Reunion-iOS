//
//  ConnectViewController.h
//

#import <UIKit/UIKit.h>
#import "BumpAPI.h"
#import "CustomBumpUI.h"
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@interface ConnectViewController : UIViewController <BumpAPIDelegate, 
UITextFieldDelegate, ABPeoplePickerNavigationControllerDelegate> {
    CustomBumpUI *customConnectUI;
}

@property (nonatomic, retain) CustomBumpUI *customBumpUI;

@end
