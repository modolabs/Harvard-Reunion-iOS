#import "KGOEventWrapper.h"

@class Note;

@interface ScheduleEventWrapper : KGOEventWrapper {
    
}

- (NSString *)placemarkID;

- (BOOL)registrationRequired;
- (BOOL)isRegistered;
- (NSString *)registrationFee;
- (NSString *)registrationURL;

- (NSString *)foursquareID;

- (Note *)note;

@end
