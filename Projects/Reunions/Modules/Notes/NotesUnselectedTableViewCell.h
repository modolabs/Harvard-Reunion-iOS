//
//  NotesUnselectedTableViewCell.h
//  Reunions
//
//  Created by Muhammad J Amjad on 4/15/11.
//  Copyright 2011 ModoLabs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NotesTextView.h"

typedef enum {
    NotesCellTypeOther,
    NotesCellLastInTable,
    NotesCellSelected
} NotesCellType;

@interface NotesUnselectedTableViewCell : UITableViewCell {
    
    UIView *_fakeCardBorder;
    UIView *_fakeBehindCardBorder;
    UIImageView *_fakeTopOfNextCell;
    
    NotesCellType notesCellType;
    
    NotesTextView * detailsView;

}

@property (nonatomic, assign) UITableView *tableView;
@property NotesCellType notesCellType;
@property (nonatomic, retain)  NotesTextView *detailsView;


@end
