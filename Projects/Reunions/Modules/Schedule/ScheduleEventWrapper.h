#import "KGOEventWrapper.h"

@interface ScheduleEventWrapper : KGOEventWrapper {
    
}

- (NSString *)placemarkID;

- (BOOL)isRegistered;
- (NSString *)registrationFee;
- (NSString *)registrationURL;

- (NSString *)facebookID;
- (NSString *)foursquareID;

@end
