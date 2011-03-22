//
//  apitestcase3ViewController.h
//  apitestcase3
//
//  Copyrights / Disclaimer
//  Copyright 2011, Bump Technologies, Inc. All rights reserved.
//  Use of the software programs described herein is subject to applicable
//  license agreements and nondisclosure agreements. Unless specifically
//  otherwise agreed in writing, all rights, title, and interest to this
//  software and documentation remain with Bump Technologies, Inc. Unless
//  expressly agreed in a signed license agreement, Bump Technologies makes
//  no representations about the suitability of this software for any purpose
//  and it is provided "as is" without express or implied warranty.
//
//  Copyright (c) 2011 Bump Technologies Inc. All rights reserved.

#import <UIKit/UIKit.h>
#import "BumpAPI.h"
#import "BumpAPICustomUI.h"

@interface apitestcase3ViewController : UIViewController<BumpAPICustomUI, BumpAPIDelegate> {
	IBOutlet UILabel *_label;
	IBOutlet UIButton *_simBump;
}

- (IBAction)simBumpPressed:(id)sender;

@end

