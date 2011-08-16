
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

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
