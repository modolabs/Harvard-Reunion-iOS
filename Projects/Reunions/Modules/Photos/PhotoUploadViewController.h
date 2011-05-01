#import <UIKit/UIKit.h>
#import "FacebookCommentViewController.h"


@class FacebookPhotosViewController;

@interface PhotoUploadViewController : UIViewController {
    
    IBOutlet UIImageView *_imageView;
    IBOutlet UIButton *_captionButton;
    
    IBOutlet UIView *_loadingView;
    IBOutlet UIActivityIndicatorView *_spinner;
    
    NSString *_caption;
}

- (IBAction)captionButtonPressed:(UIButton *)sender;
- (void)uploadButtonPressed:(id)sender;
- (void)cancelButtonPressed:(id)sender;

@property(nonatomic, retain) UIButton *captionButton;
@property(nonatomic, retain) NSString *caption;
@property(nonatomic, retain) UIImage *photo;
@property(nonatomic, retain) NSString *profile;

// might make this a delegate later
@property(nonatomic, assign) FacebookPhotosViewController *parentVC;

@end


@interface FacebookPhotoCaptionViewController : FacebookCommentViewController {
    
}

@property (nonatomic, assign) PhotoUploadViewController *parentVC;

@end
