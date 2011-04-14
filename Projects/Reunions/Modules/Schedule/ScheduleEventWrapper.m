#import "ScheduleEventWrapper.h"
#import "Foundation+KGOAdditions.h"
#import "KGOEventContactInfo.h"
#import "KGOAttendeeWrapper.h"
#import "CoreDataManager.h"

@implementation ScheduleEventWrapper

- (NSString *)subtitle
{
    return self.briefLocation;
}

- (void)updateWithDictionary:(NSDictionary *)dictionary
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    
    self.title = [dictionary stringForKey:@"title" nilIfEmpty:YES];
    self.summary = [dictionary stringForKey:@"description" nilIfEmpty:YES];
    
    // times
    NSTimeInterval startTimestamp = [dictionary floatForKey:@"start"];
    self.startDate = [NSDate dateWithTimeIntervalSince1970:startTimestamp];

    NSTimeInterval endTimestamp = [dictionary floatForKey:@"end"];
    if (endTimestamp > startTimestamp) {
        self.endDate = [NSDate dateWithTimeIntervalSince1970:endTimestamp];
    }
    NSNumber *allDay = [dictionary objectForKey:@"allday"];
    if (allDay && [allDay isKindOfClass:[NSNumber class]]) {
        self.allDay = [allDay boolValue];
    } else {
        self.allDay = (endTimestamp - startTimestamp) + 1 >= 24 * 60 * 60;
    }
    
    // location
    NSDictionary *locationDict = [dictionary dictionaryForKey:@"location"];
    self.briefLocation = [locationDict stringForKey:@"title" nilIfEmpty:YES];
    
    NSArray *latlon = [locationDict arrayForKey:@"latlon"];
    if (latlon && latlon.count == 2) {
        self.coordinate = CLLocationCoordinate2DMake([latlon floatAtIndex:0], [latlon floatAtIndex:1]);
    }
    
    NSDictionary *addressDict = [locationDict dictionaryForKey:@"address"];
    NSMutableArray *addressArray = [NSMutableArray array];
    NSString *value = [addressDict stringForKey:@"street" nilIfEmpty:YES];
    if (value) [addressArray addObject:value];
    value = [addressDict stringForKey:@"city" nilIfEmpty:YES];
    if (value) [addressArray addObject:value];
    value = [addressDict stringForKey:@"state" nilIfEmpty:YES];
    if (value) [addressArray addObject:value];
    if (addressArray.count) {
        self.location = [addressArray componentsJoinedByString:@", "];
    }
    
    NSString *building = [locationDict stringForKey:@"building" nilIfEmpty:YES];
    if (building) {
        [userInfo setObject:building forKey:@"building"];
    }
    
    // checkins
    NSString *foursquarePlaceID = [locationDict stringForKey:@"foursquareId" nilIfEmpty:YES];
    if (foursquarePlaceID) {
        [userInfo setObject:foursquarePlaceID forKey:@"foursquareID"];
    }
    
    self.lastUpdate = [NSDate date];
    
    // contact info
    NSMutableSet *organizers = [NSMutableSet set];
    
    NSString *url = [dictionary stringForKey:@"url" nilIfEmpty:YES];
    if (url) {
        // TODO: this won't work once we actually implement initWithDictionary
        KGOAttendeeWrapper *attendee = [[[KGOAttendeeWrapper alloc] initWithDictionary:nil] autorelease];
        attendee.identifier = url;
        // TODO: clean this up
        KGOEventContactInfo *contactInfo = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:@"KGOEventContactInfo"];
        attendee.contactInfo = [NSSet setWithObject:contactInfo];
        contactInfo.type = @"url";
        contactInfo.value = url;
        [organizers addObject:attendee];
    }
    
    NSString *phone = [dictionary stringForKey:@"phone" nilIfEmpty:YES];
    if (phone) {
        KGOAttendeeWrapper *attendee = [[[KGOAttendeeWrapper alloc] initWithDictionary:nil] autorelease];
        attendee.identifier = phone;
        KGOEventContactInfo *contactInfo = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:@"KGOEventContactInfo"];
        contactInfo.type = @"phone";
        contactInfo.value = phone;
        attendee.contactInfo = [NSSet setWithObject:contactInfo];
        [organizers addObject:attendee];
    }
    
    NSString *email = [dictionary stringForKey:@"email" nilIfEmpty:YES];
    if (email) {
        KGOAttendeeWrapper *attendee = [[[KGOAttendeeWrapper alloc] initWithDictionary:nil] autorelease];
        attendee.identifier = email;
        KGOEventContactInfo *contactInfo = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:@"KGOEventContactInfo"];
        contactInfo.type = @"email";
        contactInfo.value = email;
        attendee.contactInfo = [NSSet setWithObject:contactInfo];
        [organizers addObject:attendee];
    }
    
    self.organizers = organizers;
    
    // registration info
    NSDictionary *registrationInfo = [dictionary dictionaryForKey:@"registration"];
    if (registrationInfo) {
        if ([registrationInfo boolForKey:@"registered"]) {
            [userInfo setObject:[NSNumber numberWithBool:YES] forKey:@"registered"];
        }
        NSString *value = [registrationInfo stringForKey:@"fee" nilIfEmpty:YES];
        if (value) {
            [userInfo setObject:value forKey:@"fee"];
        }
        value = [registrationInfo stringForKey:@"url" nilIfEmpty:YES];
        if (value) {
            [userInfo setObject:value forKey:@"regURL"];
        }
    }
    
    self.userInfo = userInfo;
    
    NSArray *attendees = [dictionary arrayForKey:@"attendees"];
    if (attendees) {
        NSMutableSet *attendeeSet = [NSMutableSet setWithCapacity:attendees.count];
        for (NSDictionary *attendeeDict in attendees) {
            KGOAttendeeWrapper *attendee = [[[KGOAttendeeWrapper alloc] initWithDictionary:attendeeDict] autorelease];
            [attendeeSet addObject:attendee];
        }
        self.attendees = [NSSet setWithSet:attendeeSet];
    }
}

- (NSString *)placemarkID
{
    return [self.userInfo objectForKey:@"building"];
}

- (BOOL)isRegistered
{
    return [self.userInfo boolForKey:@"registered"];
}

- (NSString *)registrationFee
{
    return [self.userInfo objectForKey:@"fee"];
}

- (NSString *)registrationURL
{
    return [self.userInfo objectForKey:@"regURL"];
}

- (NSString *)foursquareID
{
    return [self.userInfo objectForKey:@"foursquareID"];
}

@end
