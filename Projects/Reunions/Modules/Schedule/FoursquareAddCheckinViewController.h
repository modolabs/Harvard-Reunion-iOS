#import <UIKit/UIKit.h>

@class FoursquareCheckinViewController;
@protocol KGOFoursquareCheckinDelegate;

@interface FoursquareAddCheckinViewController : UIViewController <UITextViewDelegate> {
    
    IBOutlet UITextView *_textView;
    IBOutlet UIView *_loadingViewContainer;
    IBOutlet UIActivityIndicatorView *_spinner;
    BOOL _textEditBegun;    
}

@property(nonatomic, retain) NSString *venue;
@property(nonatomic, retain) NSString *shout;
@property(nonatomic, retain) FoursquareCheckinViewController *parent;

- (IBAction)submitButtonPressed:(id)sender;
- (IBAction)cancelButtonPressed:(id)sender;

@end
