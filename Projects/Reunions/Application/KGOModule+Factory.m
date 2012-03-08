
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import "KGOModule+Factory.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "KGOModule.h"
#import "AboutModule.h"
#import "AttendeesModule.h"
#import "CalendarModule.h"
#import "ExternalURLModule.h"
#import "FacebookModule.h"
#import "FoursquareModule.h"
#import	"ReunionMapModule.h"
#import "ReunionNewsModule.h"
#import "PeopleModule.h"
#import "PhotosModule.h"
#import "ReunionHomeModule.h"
#import "ReunionLoginModule.h"
#import "ScheduleModule.h"
#import "SettingsModule.h"
#import "TwitterModule.h"
#import "VideosModule.h"
#import "ConnectModule.h"
#import "NotesModule.h"

@implementation KGOModule (Factory)

+ (KGOModule *)moduleWithDictionary:(NSDictionary *)args {
    KGOModule *module = nil;
    NSString *className = [args objectForKey:@"class"];
    if (!className) {
        NSDictionary *moduleMap = [NSDictionary dictionaryWithObjectsAndKeys:
                                   @"AboutModule", @"about",
                                   @"AttendeesModule", @"attendees",
                                   @"ScheduleModule", @"schedule",
                                   @"FoursquareModule", @"foursquare",
                                   @"HomeModule", @"home",
                                   @"LoginModule", @"login",
                                   @"MapModule", @"map",
                                   @"NewsModule", @"news",
                                   @"PeopleModule", @"people",
                                   @"SettingsModule", @"customize",
                                   @"NotesModule", @"notes",
                                   nil];
        
        NSString *serverID = [args objectForKey:@"id"];
        className = [moduleMap objectForKey:serverID];
        
        DLog(@"%@", args);
    }
    
    if ([className isEqualToString:@"AttendeesModule"])
        module = [[[AttendeesModule alloc] initWithDictionary:args] autorelease];
    
    if ([className isEqualToString:@"AboutModule"])
        module = [[[AboutModule alloc] initWithDictionary:args] autorelease];
    
    if ([className isEqualToString:@"ScheduleModule"])
        module = [[[ScheduleModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"HomeModule"])
        module = [[[ReunionHomeModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"ExternalURLModule"])
        module = [[[ExternalURLModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"FacebookModule"])
        module = [[[FacebookModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"FoursquareModule"])
        module = [[[FoursquareModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"LoginModule"])
        module = [[[ReunionLoginModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"MapModule"])
        module = [[[ReunionMapModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"NewsModule"])
        module = [[[ReunionNewsModule alloc] initWithDictionary:args] autorelease];
    
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
    
    else if ([className isEqualToString:@"ConnectModule"])
        module = [[[ConnectModule alloc] initWithDictionary:args] autorelease];   
    
    else if ([className isEqualToString:@"NotesModule"]) {
        
        KGONavigationStyle navStyle = [KGO_SHARED_APP_DELEGATE() navigationStyle];
        if (navStyle == KGONavigationStyleTabletSidebar) 
            module = [[[NotesModule alloc] initWithDictionary:args] autorelease]; 
    }
    
    return module;
}

@end
