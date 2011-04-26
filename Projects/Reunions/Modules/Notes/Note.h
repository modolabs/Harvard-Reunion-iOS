#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface Note : NSManagedObject {
}

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * details;
@property (nonatomic, retain) NSString * eventIdentifier;


+ (NSString * ) dateToDisplay: (NSDate *) date;

+ (NSString *) noteTitleFromDetails: (NSString *) noteDetails;

+ (void) printContent: (NSString *) textToPrint jobTitle:(NSString *) jobTitle 
           fromButton:(UIButton *) button parentView: (UIView *) parentView delegate:(id <UIPrintInteractionControllerDelegate>) delegate;

@end
