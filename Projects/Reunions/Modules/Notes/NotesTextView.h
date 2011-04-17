//
//  NotesTextView.h
//  Reunions
//
//  Created by Muhammad J Amjad on 4/15/11.
//  Copyright 2011 ModoLabs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#define MIN_HEIGHT = 250
#define MAX_HEIGHT = 350;

@interface NotesTextView : UIView <UIActionSheetDelegate>{
    
    UIView * titleView;
    UITextView * detailsView;
}

@property (nonatomic, retain) NSString * cellTextLabel;
@property (nonatomic, retain) NSString * cellDetailText;
@property (nonatomic, retain) NSString * details;

- (id)initWithFrame:(CGRect)frame titleText:(NSString * ) titleText detailText: (NSString *) detailText;

@end
