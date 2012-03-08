
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import "KGODetailPageHeaderView.h"

@interface ReunionDetailPageHeaderView : KGODetailPageHeaderView <UIAlertViewDelegate> {
    
    UIButton *_calendarButton;
    
}

- (void)layoutCalendarButton;

@end
