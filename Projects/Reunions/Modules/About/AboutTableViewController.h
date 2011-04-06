#import <UIKit/UIKit.h>
#import "KGORequestManager.h"
#import "KGOTableViewController.h"

@interface AboutTableViewController : KGOTableViewController <KGORequestDelegate> {
    
    NSArray *_paragraphs;
    NSArray *_sections;

}

@property (nonatomic, retain) KGORequest * request;
@property (nonatomic, retain) NSString * moduleTag;

@end
