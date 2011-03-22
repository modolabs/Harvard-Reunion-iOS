//
//  BumpViewController.h
//  Universitas
//
//  Created by Jim Kang on 3/22/11.
//  Copyright 2011 Modo Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BumpAPI.h"
#import "CustomBumpUI.h"

@interface BumpViewController : UIViewController <BumpAPIDelegate, 
UITextFieldDelegate> {
    CustomBumpUI *customBumpUI;
}

@property (nonatomic, retain) CustomBumpUI *customBumpUI;

@end
