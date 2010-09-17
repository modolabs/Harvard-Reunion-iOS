//
//  ShuttlesMainViewController.h
//  Harvard Mobile
//
//  Created by Muhammad Amjad on 9/17/10.
//  Copyright 2010 Modo Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShuttlesTabViewControl.h"
#import "ShuttleRoutes.h"


@interface ShuttlesMainViewController : UIViewController<TabViewControlDelegate> {
	
	ShuttleRoutes *shuttleRoutesTableView; 
	
	IBOutlet UIView *tabViewContainer;
	
	NSMutableArray *_tabViewsArray;
	
	IBOutlet ShuttlesTabViewControl *tabView;

}

@end
