#import "KGOModule+Factory.h"
#import "KGOModule.h"
#import "AboutModule.h"
#import "CalendarModule.h"
#import "ExternalURLModule.h"
#import "FacebookModule.h"
#import "FoursquareModule.h"
#import "HomeModule.h"
#import "LoginModule.h"
#import	"ReunionMapModule.h"
#import "NewsModule.h"
#import "PeopleModule.h"
#import "PhotosModule.h"
#import "ScheduleModule.h"
#import "SettingsModule.h"
#import "TwitterModule.h"
#import "VideosModule.h"

@implementation KGOModule (Factory)

+ (KGOModule *)moduleWithDictionary:(NSDictionary *)args {
    KGOModule *module = nil;
    NSString *className = [args objectForKey:@"class"];
    if (!className) {
        NSDictionary *moduleMap = [NSDictionary dictionaryWithObjectsAndKeys:
                                   @"AboutModule", @"about",
                                   @"ScheduleModule", @"schedule",
                                   @"FoursquareModule", @"foursquare",
                                   @"HomeModule", @"home",
                                   @"LoginModule", @"login",
                                   @"ReunionMapModule", @"map",
                                   @"NewsModule", @"news",
                                   @"PeopleModule", @"people",
                                   @"SettingsModule", @"customize",
                                   nil];
        
        NSString *serverID = [args objectForKey:@"id"];
        className = [moduleMap objectForKey:serverID];
        
        NSLog(@"%@", args);
    }
    
    if ([className isEqualToString:@"AboutModule"])
        module = [[[AboutModule alloc] initWithDictionary:args] autorelease];
    
    if ([className isEqualToString:@"ScheduleModule"])
        module = [[[ScheduleModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"HomeModule"])
        module = [[[HomeModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"ExternalURLModule"])
        module = [[[ExternalURLModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"FacebookModule"])
        module = [[[FacebookModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"FoursquareModule"])
        module = [[[FoursquareModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"LoginModule"])
        module = [[[LoginModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"ReunionMapModule"])
        module = [[[ReunionMapModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"NewsModule"])
        module = [[[NewsModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"PeopleModule"])
        module = [[[PeopleModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"PhotosModule"])
        module = [[[PhotosModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"SettingsModule"])
        module = [[[SettingsModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"TwitterModule"])
        module = [[[TwitterModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"VideosModule"])
        module = [[[VideosModule alloc] initWithDictionary:args] autorelease];
    
    return module;
}

@end
