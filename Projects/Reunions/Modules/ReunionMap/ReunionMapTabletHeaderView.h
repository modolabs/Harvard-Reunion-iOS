
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import "ReunionMapDetailHeaderView.h"


@interface ReunionMapTabletHeaderView : ReunionMapDetailHeaderView {
    
    UIButton *_closeButton;
    UIButton *_pulltabButton;
    
}

@property (nonatomic, readonly) UIButton *closeButton;
@property (nonatomic, readonly) UIButton *pulltabButton;

@end
