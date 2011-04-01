#import "KGOSocialMediaController.h"

@interface KGOSocialMediaController (Foursquare)

- (void)startupFoursquare;
- (void)shutdownFoursquare;
- (void)loginFoursquare;

- (void)didReceiveFoursquareAuthCode:(NSString *)code;


@end
