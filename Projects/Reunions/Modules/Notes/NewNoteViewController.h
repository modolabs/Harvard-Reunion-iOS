//
//  NewNoteViewController.h
//  Reunions
//
//  Created by Muhammad J Amjad on 4/16/11.
//  Copyright 2011 ModoLabs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#define NEWNOTE_XOFFSET 140
#define NEWNOTE_YOFFSET 75
#define NEWNOTE_WIDTH 600
#define NEWNOTE_HEIGHT 675

#ifndef __NOTESMODALVIEW__
#define __NOTESMODALVIEW__
@protocol NotesModalViewDelegate <NSObject>

@required
/* notifies the notesmodalviewdeletgate to delete the Note and not save
 */
- (void)deleteNoteWithoutSaving;

@end
#endif


@interface NewNoteViewController : UIViewController <UIActionSheetDelegate>{
    
    UIView * titleView;
    UITextView * textView;
    
}

@property (nonatomic, retain) NSString * titleText;
@property (nonatomic, retain) NSString * dateText;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * eventIdentifier;
@property (nonatomic, assign) double width;
@property (nonatomic, assign) double  height;
@property (nonatomic, retain) NSString * textViewString;
@property (nonatomic, assign) UIViewController<NotesModalViewDelegate> * viewControllerBackground;


-(id) initWithTitleText: (NSString *) title date: (NSDate *) dateCreated andDateText: (NSString *) dateString  eventId: (NSString *) eventId viewWidth: (double) viewWidth viewHeight: (double) viewHeight;

@end
