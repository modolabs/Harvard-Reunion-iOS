#import <Foundation/Foundation.h>

@class KGOFoursquareRequest;

@protocol KGOFoursquareRequestDelegate <NSObject>

- (void)foursquareRequest:(KGOFoursquareRequest *)request didSucceedWithResponse:(NSDictionary *)response;
- (void)foursquareRequest:(KGOFoursquareRequest *)request didFailWithError:(NSError *)error;

@end



typedef enum {
    FoursquareBroadcastLevelPrivate = 0,
    FoursquareBroadcastLevelPublic = 1 << 1,
    FoursquareBroadcastLevelTwitter = 1 << 2,
    FoursquareBroadcastLevelFacebook = 1 << 3
} FoursquareBroadcastLevel;



@interface KGOFoursquareRequest : NSObject {
    
    NSURLConnection *_connection;
    NSMutableData *_data;
    
    NSString *_httpMethod;
    BOOL _isPostRequest;
    NSDictionary *_postParams;

}

- (void)checkinToVenueID:(NSString *)venueID broadcastLevel:(NSUInteger)level message:(NSString *)message;
- (void)requestCheckinsForVenueID:(NSString *)venueID;
- (void)requestFromURL:(NSString *)urlString;

- (NSString *)fullURLString;

@property(nonatomic, retain) NSString *resourceName;
@property(nonatomic, retain) NSString *resourceID;
@property(nonatomic, retain) NSString *command;
@property(nonatomic, retain) NSDictionary *params;
@property(nonatomic, assign) id<KGOFoursquareRequestDelegate> delegate;

@end




@interface KGOFoursquareEngine : NSObject <KGOFoursquareRequestDelegate> {
    
    NSString *_oauthToken;
    KGOFoursquareRequest *_oauthRequest;
    
}

@property(nonatomic, retain) NSString *clientID;
@property(nonatomic, retain) NSString *clientSecret;
@property(nonatomic, retain) NSString *authCode;

// in constructing this uri we require an instance of FoursquareModule with
// the tag "foursquare".  anything else will not work right now.
@property(nonatomic, retain) NSString *redirectURI;




- (KGOFoursquareRequest *)requestWithDelegate:(id<KGOFoursquareRequestDelegate>)delegate;

- (void)authorize;
- (void)requestOAuthToken;
- (void)logout;
- (BOOL)isLoggedIn;

@end
