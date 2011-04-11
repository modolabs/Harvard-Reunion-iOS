#import "KGOEventWrapper.h"

@interface ScheduleEventWrapper : KGOEventWrapper {
    
}

- (BOOL)isRegistered;
- (NSString *)registrationFee;
- (NSString *)registrationURL;

- (NSString *)facebookID;
- (NSString *)foursquareID;

@end
