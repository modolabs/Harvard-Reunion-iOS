
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import <UIKit/UIKit.h>
#import "Note.h"
#import <MessageUI/MFMailComposeViewController.h>
#import <UIKit/UIPrintInteractionController.h>


@class NotesTextView;

@protocol NotesTextViewDelegate <NSObject>

@required
/* notifies the parenttableviewcontroller to delete the Note and reload
 */
- (void)deleteNoteAndReload:(Note*)note;

@end

@interface NotesTextView : UIView <UIActionSheetDelegate, UITextViewDelegate, MFMailComposeViewControllerDelegate, UIPrintInteractionControllerDelegate>{
    
    //UIView * titleView;
    UITextView * detailsView;
    Note * note;
    BOOL becomeFirstResponder;
    
    UIViewController <NotesTextViewDelegate> *delegate;
    
    //UIButton * printButton;
    UIButton *deleteButton;
}

@property(nonatomic, assign) UIViewController <NotesTextViewDelegate> *delegate;

- (id)initWithFrame:(CGRect)frame titleText:(NSString * ) titleText detailText: (NSString *) dateText noteText: (NSString *) noteText note:(Note *) savedNote firstResponder:(BOOL) firstResponder dateFont:(UIFont *) font;

-(void) saveNote;

@end
