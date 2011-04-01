#import "KGOSocialMediaController+Foursquare.h"
#import "KGOFoursquareEngine.h"
#import "KGOWebViewController.h"
#import "KGOAppDelegate.h"

@implementation KGOSocialMediaController (Foursquare)

- (void)startupFoursquare {
    _foursquareStartupCount++;
    if (!_foursquareEngine) {
        _foursquareEngine = [[KGOFoursquareEngine alloc] init];
        _foursquareEngine.clientID = [[_appConfig objectForKey:KGOSocialMediaTypeFoursquare] objectForKey:@"ClientID"];
        _foursquareEngine.clientSecret = [[_appConfig objectForKey:KGOSocialMediaTypeFoursquare] objectForKey:@"ClientSecret"];
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

- (void)loginFoursquare
{
    [_foursquareEngine authorize];
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
