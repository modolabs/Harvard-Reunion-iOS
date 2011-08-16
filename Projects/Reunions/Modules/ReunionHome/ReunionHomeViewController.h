
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import "KGOPortletHomeViewController.h"

@class ReunionHomeModule;

@interface ReunionHomeViewController : KGOPortletHomeViewController {

    NSArray *_subclassPrimaryModules;
    NSArray *_subclassSecondaryModules;
}

@property(nonatomic, assign) ReunionHomeModule *homeModule;

@end
