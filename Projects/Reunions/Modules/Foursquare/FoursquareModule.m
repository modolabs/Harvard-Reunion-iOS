#import "FoursquareModule.h"
#import "KGOSocialMediaController+Foursquare.h"
#import "Foundation+KGOAdditions.h"

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
        
        [[KGOSocialMediaController sharedController] didReceiveFoursquareAuthCode:code];
        
        return YES;
    }
    return NO;
}

- (void)applicationDidFinishLaunching {
    [[KGOSocialMediaController sharedController] startupFoursquare];
}

- (void)applicationWillTerminate {
    [[KGOSocialMediaController sharedController] shutdownFoursquare];
}

- (void)applicationDidEnterBackground {
}

- (void)applicationWillEnterForeground {
}

#pragma mark Social media controller

- (NSSet *)socialMediaTypes {
    return [NSSet setWithObject:KGOSocialMediaTypeFoursquare];
}

@end
