#import "KGOSocialMediaController.h"

extern NSString * const FoursquareDidLoginNotification;
extern NSString * const FoursquareDidLogoutNotification;

@interface KGOSocialMediaController (foursquare)

- (void)startupFoursquare;
- (void)shutdownFoursquare;
- (void)loginFoursquare;
- (void)logoutFoursquare;

- (void)didReceiveFoursquareAuthCode:(NSString *)code;

- (BOOL)isFoursquareLoggedIn;

- (KGOFoursquareEngine *)foursquareEngine;

@end
