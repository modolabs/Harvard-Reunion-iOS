//
//  ConnectViewController.h
//

#import <UIKit/UIKit.h>
#import "BumpAPI.h"
#import "CustomBumpUI.h"

@interface ConnectViewController : UIViewController <BumpAPIDelegate, 
UITextFieldDelegate> {
    CustomBumpUI *customConnectUI;
}

@property (nonatomic, retain) CustomBumpUI *customBumpUI;

@end
