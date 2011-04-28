#import "FoursquareModule.h"
#import "Foundation+KGOAdditions.h"
#import "KGOSocialMediaController.h"

#define FACEBOOK_STATUS_POLL_FREQUENCY 60

@implementation FoursquareModule

#pragma mark -

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    return nil;
}

- (BOOL)handleLocalPath:(NSString *)localPath query:(NSString *)query {
    if ([localPath isEqualToString:@"authorize"]) {
        NSDictionary *queryParts = [NSURL parametersFromQueryString:query];
        NSString *code = [queryParts stringForKey:@"code" nilIfEmpty:YES];
        
        [[KGOSocialMediaController foursquareService] didReceiveFoursquareAuthCode:code];
        
        return YES;
    }
    return NO;
}

- (void)applicationDidFinishLaunching {
    [[KGOSocialMediaController foursquareService] startup];
}

- (void)applicationWillTerminate {
    [[KGOSocialMediaController foursquareService] shutdown];
}

- (void)applicationDidEnterBackground {
}

- (void)applicationWillEnterForeground {
}

- (NSArray *)applicationStateNotificationNames
{
    return [NSArray arrayWithObjects:FoursquareDidLoginNotification, FoursquareDidLogoutNotification, nil];
}

#pragma mark Social media controller

- (NSSet *)socialMediaTypes {
    return [NSSet setWithObject:KGOSocialMediaTypeFoursquare];
}

@end
