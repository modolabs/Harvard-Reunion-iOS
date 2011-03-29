#import "ScheduleEventWrapper.h"
#import "Foundation+KGOAdditions.h"
#import "KGOEventContactInfo.h"
#import "KGOAttendeeWrapper.h"
#import "CoreDataManager.h"

@implementation ScheduleEventWrapper

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    NSString *identifier = [dictionary stringForKey:@"id" nilIfEmpty:YES];
    if (!identifier) {
        [self release];
        return nil;
    }
    
    self = [super init];
    if (self) {
        self.identifier = identifier;
        self.title = [dictionary stringForKey:@"title" nilIfEmpty:YES];
        self.summary = [dictionary stringForKey:@"description" nilIfEmpty:YES];

        // times
        NSTimeInterval startTimestamp = [dictionary floatForKey:@"start"];
        if (startTimestamp) {
            self.startDate = [NSDate dateWithTimeIntervalSince1970:startTimestamp];
        }
        NSTimeInterval endTimestamp = [dictionary floatForKey:@"end"];
        if (endTimestamp) {
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
        self.location = [addressDict stringForKey:@"street" nilIfEmpty:YES];

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
        if (url) {
            KGOAttendeeWrapper *attendee = [[[KGOAttendeeWrapper alloc] initWithDictionary:nil] autorelease];
            attendee.identifier = phone;
            KGOEventContactInfo *contactInfo = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:@"KGOEventContactInfo"];
            contactInfo.type = @"phone";
            contactInfo.value = phone;
            attendee.contactInfo = [NSSet setWithObject:contactInfo];
            [organizers addObject:attendee];
        }
        
        NSString *email = [dictionary stringForKey:@"email" nilIfEmpty:YES];
        if (url) {
            KGOAttendeeWrapper *attendee = [[[KGOAttendeeWrapper alloc] initWithDictionary:nil] autorelease];
            attendee.identifier = email;
            KGOEventContactInfo *contactInfo = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:@"KGOEventContactInfo"];
            contactInfo.type = @"email";
            contactInfo.value = email;
            attendee.contactInfo = [NSSet setWithObject:contactInfo];
            [organizers addObject:attendee];
        }
        
        self.organizers = organizers;
        NSLog(@"organizers: %@", organizers);
    }
    return self;
}

@end
