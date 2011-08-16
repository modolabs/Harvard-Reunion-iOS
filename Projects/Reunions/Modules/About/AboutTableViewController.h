
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import <UIKit/UIKit.h>
#import "KGORequestManager.h"
#import "KGOTableViewController.h"

extern NSString * const AboutParagraphsPrefKey;
extern NSString * const AboutSectionsPrefKey;

@interface AboutTableViewController : KGOTableViewController <KGORequestDelegate> {
    
    NSArray *_paragraphs;
    NSArray *_sections;

}

@property (nonatomic, retain) KGORequest * request;
@property (nonatomic, retain) NSString * moduleTag;

@end
