#import "ScheduleDataManager.h"
#import "ScheduleEventWrapper.h"

#define EVENT_TIMEOUT -3600

@implementation ScheduleDataManager

/*

{"id":"http:\/\/uid.trumba.com\/event\/93747775",
    "category":"reunion",
    "location":{
        "title":"Eliot House Courtyard",
        "building":null,
        "latlon":["42.37019","-71.121471"],
        "address":{"street":null,"city":null,"state":null},
        "multiple":false,
        "fbPlaceId":null,
        "fqPlaceId":null},
    "registration":{
        "url":"http:\/\/alumni.harvard.edu\/",
        "fee":"$80",
        "registered":true},
    "attendees":[{
        "prefix":"Ms.",
        "first_name":"Alexis",
        "last_name":"Ellwood",
        "suffix":"",
        "class_year":"2001",
        "display_name":"Alexis Ellwood "}],
    "title":"Welcome Cocktail Reception",
    "description":null,
    "url":null,
    "phone":null,
    "email":null,
    "start":"1306540800",
    "end":"1306558800",
    "allday":false,
    "registered":true}
*/

- (BOOL)requestGroups
{
    BOOL success = NO;
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortOrder" ascending:YES];
    NSArray *oldGroups = [[CoreDataManager sharedManager] objectsForEntity:KGOEntityNameCalendarGroup
                                                         matchingPredicate:nil
                                                           sortDescriptors:[NSArray arrayWithObject:sort]];
    
    if (oldGroups) {
        success = YES;
        [self.delegate groupsDidChange:oldGroups];
    }
    
    // TODO: dont' hard code timeout value
    NSPredicate *timeoutPredicate = [NSPredicate predicateWithFormat:@"lastUpdate < %@", [NSDate dateWithTimeIntervalSinceNow:-3600]];
    id event = [[[CoreDataManager sharedManager] objectsForEntity:KGOEntityNameEvent matchingPredicate:timeoutPredicate] lastObject];
    if (event) {
        return success;
    }
    
    // TODO: use a timeout value to decide whether or not to check for update
    if ([[KGORequestManager sharedManager] isReachable]) {
        if(_groupsRequest) {
            return success;
        }
        
        _groupsRequest = [[KGORequestManager sharedManager] requestWithDelegate:self module:self.moduleTag path:@"categories" params:nil];
        _groupsRequest.expectedResponseType = [NSDictionary class];
        [_groupsRequest connect];
    }
    return success;
}

- (BOOL)requestEventsForCalendar:(KGOCalendar *)calendar time:(NSDate *)time
{
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            calendar.identifier, @"category",
                            calendar.type, @"type",
                            nil];
    return [self requestEventsForCalendar:calendar params:params];
}

// override superclass b/c we want to initialize ScheduleEventWrapper
- (BOOL)requestEventsForCalendar:(KGOCalendar *)calendar params:(NSDictionary *)params
{
    
    BOOL success = NO;
    NSArray *events = [calendar.events allObjects];
    if (events.count) {
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"lastUpdate < %@", [NSDate dateWithTimeIntervalSinceNow:EVENT_TIMEOUT]];
        NSArray *oldEvents = [events filteredArrayUsingPredicate:pred];
        
        if (oldEvents.count) {
            [[CoreDataManager sharedManager] deleteObjects:oldEvents];
            
        } else {
            NSMutableArray *wrappers = [NSMutableArray arrayWithCapacity:events.count];
            for (KGOEvent *event in events) {
                [wrappers addObject:[[[ScheduleEventWrapper alloc] initWithKGOEvent:event] autorelease]];
            }
            
            [self.delegate eventsDidChange:wrappers calendar:calendar];
            
            if (wrappers.count) {
                return YES;
            }
        }
    }
    
    if ([[KGORequestManager sharedManager] isReachable]) {
        NSString *requestIdentifier = calendar.identifier;
        KGORequest *request = [_eventsRequests objectForKey:requestIdentifier];
        if (request) {
            [request cancel];
            [_eventsRequests removeObjectForKey:requestIdentifier];
        }
        
        request = [[KGORequestManager sharedManager] requestWithDelegate:self module:self.moduleTag path:@"events" params:params];
        request.expectedResponseType = [NSDictionary class];
        [_eventsRequests setObject:request forKey:requestIdentifier];
        [request connect];
        
        if (request) {
            success = YES;
        }
    }
    
    return success;
}

- (BOOL)requestEventsForCalendar:(KGOCalendar *)calendar startDate:(NSDate *)startDate endDate:(NSDate *)endDate
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   calendar.identifier, @"category",
                                   calendar.type, @"type",
                                   nil];
    
    if (startDate) {
        NSString *startString = [NSString stringWithFormat:@"%.0f", [startDate timeIntervalSince1970]];
        [params setObject:startString forKey:@"start"];
    }
    
    if (endDate) {
        NSString *endString = [NSString stringWithFormat:@"%.0f", [endDate timeIntervalSince1970]];
        [params setObject:endString forKey:@"end"];
    }
    
    return [self requestEventsForCalendar:calendar params:params];
}

- (void)request:(KGORequest *)request didReceiveResult:(id)result
{
    if ([request.path isEqualToString:@"events"]) { // events
        
        NSString *calendarID = [request.getParams objectForKey:@"category"];
        KGOCalendar *calendar = [KGOCalendar calendarWithID:calendarID];
        
        // search results boilerplate
        NSInteger total = [result integerForKey:@"total"];
        NSInteger returned = [result integerForKey:@"returned"];
        if (total > returned) {
            // TODO: implement paging
        }
        //NSString *displayField = [result stringForKey:@"displayField" nilIfEmpty:YES];
        
        NSArray *eventDicts = [result arrayForKey:@"results"];
        if (returned > eventDicts.count)
            returned = eventDicts.count;
        
        NSMutableArray *array = [NSMutableArray array];
        for (NSInteger i = 0; i < returned; i++) {
            NSDictionary *aDict = [eventDicts objectAtIndex:i];
            ScheduleEventWrapper *event = [[[ScheduleEventWrapper alloc] initWithDictionary:aDict] autorelease];
            [event addCalendar:calendar];
            [array addObject:event];
            [event convertToKGOEvent];
        }
        
        [[CoreDataManager sharedManager] saveData];
        [self.delegate eventsDidChange:array calendar:calendar];
        
    } else {
        [super request:request didReceiveResult:result];
    }
}

@end
