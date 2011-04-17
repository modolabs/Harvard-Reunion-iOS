//
//  NewNoteViewController.h
//  Reunions
//
//  Created by Muhammad J Amjad on 4/16/11.
//  Copyright 2011 ModoLabs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NotesTableViewController.h"


@interface NewNoteViewController : UIViewController <UIActionSheetDelegate>{
    
    UIView * titleView;
    UITextView * textView;
    
}

@property (nonatomic, retain) NSString * titleText;
@property (nonatomic, retain) NSString * dateText;
@property (nonatomic, assign) double width;
@property (nonatomic, assign) double  height;
@property (nonatomic, retain) NSString * textViewString;
@property (nonatomic, retain) NotesTableViewController * viewControllerBackground;

-(id) initWithTitleText: (NSString *) title andDateText: (NSString *) dateString  viewWidth: (double) viewWidth viewHeight: (double) viewHeight;

@end
