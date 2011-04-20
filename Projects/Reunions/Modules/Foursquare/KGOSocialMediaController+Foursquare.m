#import "KGOSocialMediaController+Foursquare.h"
#import "KGOFoursquareEngine.h"
#import "KGOWebViewController.h"
#import "KGOAppDelegate.h"
#import "Foundation+KGOAdditions.h"

@implementation KGOSocialMediaController (foursquare)

- (void)startupFoursquare {
    _foursquareStartupCount++;
    if (!_foursquareEngine) {
        _foursquareEngine = [[KGOFoursquareEngine alloc] init];
        NSDictionary *foursquareConfig = [_appConfig objectForKey:KGOSocialMediaTypeFoursquare];
        _foursquareEngine.clientID = [foursquareConfig stringForKey:@"ClientID" nilIfEmpty:YES];
        _foursquareEngine.clientSecret = [foursquareConfig stringForKey:@"ClientSecret" nilIfEmpty:YES];
    }
}

- (void)shutdownFoursquare
{
    if (_foursquareStartupCount > 0)
        _foursquareStartupCount--;
    if (_foursquareStartupCount <= 0) {
        [_foursquareEngine release];
        _foursquareEngine = nil;
    }
}

- (BOOL)isFoursquareLoggedIn
{
    return [_foursquareEngine isLoggedIn];
}

- (void)loginFoursquare
{
    NSLog(@"%@ %@", _foursquareEngine.clientSecret, _foursquareEngine.clientID);
    [_foursquareEngine authorize];
}

- (void)logoutFoursquare
{
    [_foursquareEngine logout];
}

- (void)didReceiveFoursquareAuthCode:(NSString *)code
{
    _foursquareEngine.authCode = code;
    [_foursquareEngine requestOAuthToken];
}

- (KGOFoursquareEngine *)foursquareEngine
{
    return _foursquareEngine;
}


@end
