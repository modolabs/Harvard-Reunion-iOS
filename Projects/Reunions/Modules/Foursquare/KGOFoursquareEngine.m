#import "KGOFoursquareEngine.h"
#import "JSON.h"
#import "KGOWebViewController.h"
#import "KGOAppDelegate.h"
#import "Foundation+KGOAdditions.h"

NSString * const FoursquareDidLoginNotification = @"foursquareDidLogin";
NSString * const FoursquareDidLogoutNotification = @"foursquareDidLogout";

static NSString * const FoursquareBaseURL = @"https://api.foursquare.com/v2/";

@implementation KGOFoursquareRequest

@synthesize delegate, resourceName, resourceID, command, params, postParams, isPostRequest;

- (NSString *)fullURLString
{
    NSMutableArray *pathComponents = [NSMutableArray arrayWithObjects:FoursquareBaseURL, self.resourceName, nil];
    if (self.resourceID) {
        [pathComponents addObject:self.resourceID];
    }
    [pathComponents addObject:self.command];
    
    NSString *baseURL = [pathComponents componentsJoinedByString:@"/"];
    NSString *query = [NSURL queryStringWithParameters:self.params];
    
    return [NSString stringWithFormat:@"%@?%@", baseURL, query];
}

- (void)connect
{
    [self requestFromURL:[self fullURLString]];
}

- (void)requestFromURL:(NSString *)urlString
{
    if (_connection) {
        return;
    }
    
    NSLog(@"foursquare: requesting from %@", urlString);
    
    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]
                                                                 cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                             timeoutInterval:30] autorelease];
    
    if (self.isPostRequest) {
        [request setHTTPMethod:@"POST"];
        self.isPostRequest = NO;
    }
    
    if (self.postParams) {
        NSError *error = nil;
        [request setHTTPBody:[NSPropertyListSerialization dataWithPropertyList:_postParams
                                                                        format:NSPropertyListBinaryFormat_v1_0
                                                                       options:0
                                                                         error:&error]];
        [self.postParams release];
        self.postParams = nil;

         if (error) {
            NSLog(@"problem setting http post body: %@", [error description]);
            return;
        }
    }
    
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if (!_data) {
        _data = [[NSMutableData alloc] init];
    }
    [_data setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_data appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [_data release];
    _data = nil;
    [_connection release];
    _connection = nil;
    
    [self.delegate foursquareRequest:self didFailWithError:error];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    SBJsonParser *parser = [[[SBJsonParser alloc] init] autorelease];
    id result = [parser objectWithData:_data];
    
    if ([result isKindOfClass:[NSDictionary class]]) {
        DLog(@"%@", [result description]);
        id errorInfo = [result objectForKey:@"error"];
        if (errorInfo) {
            NSError *error = [NSError errorWithDomain:@"com.modolabs.foursquareEngine" code:1 userInfo:errorInfo];
            [self.delegate foursquareRequest:self didFailWithError:error];
            
        } else {
            NSDictionary *response = [result dictionaryForKey:@"response"];
            if (response) {
                [self.delegate foursquareRequest:self didSucceedWithResponse:response];
            } else {
                [self.delegate foursquareRequest:self didSucceedWithResponse:result];
            }
        }
        
    } else {
        NSLog(@"received result that was not a dictionary: %@", [result description]);
    }
    
    [_connection release];
    _connection = nil;
    [_data release];
    _data = nil;
}

- (void)dealloc
{
    if (_connection) {
        [_connection cancel];
    }
    self.postParams = nil;
    [_data release];
    
    [super dealloc];
}

@end




@interface KGOFoursquareCheckinPair : NSObject {
}

@property (nonatomic, retain) NSDictionary *userData;
@property (nonatomic, assign) id<KGOFoursquareCheckinDelegate> delegate;
@property (nonatomic, assign) KGOFoursquareRequest *request;

@end


@implementation KGOFoursquareCheckinPair

@synthesize delegate, request, userData;

- (void)dealloc
{
    self.userData = nil;
    self.delegate = nil;
    self.request = nil;
    [super dealloc];
}

@end



@implementation KGOFoursquareEngine

static NSString * const FoursquareOAuthTokenKey = @"4squareToken";
static NSString * const FoursquareOAuthExpirationDate = @"4squareExpiration";

@synthesize authCode, redirectURI, clientID, clientSecret;

- (KGOFoursquareRequest *)checkinRequestWithDelegate:(id<KGOFoursquareRequestDelegate>)delegate
                                               venue:(NSString *)venue
                                      broadcastLevel:(NSUInteger)level
                                             message:(NSString *)message
{
    KGOFoursquareRequest *request = [self requestWithDelegate:delegate];
    
    request.resourceName = @"checkins";
    request.command = @"add";
    
    NSMutableDictionary *mutableParams = [[request.params mutableCopy] autorelease];
    
    [mutableParams setObject:venue forKey:@"venueId"];
    
    NSMutableArray *values = [NSMutableArray array];
    if (level == FoursquareBroadcastLevelPrivate) {
        [values addObject:@"private"];
    } else {
        if (level & FoursquareBroadcastLevelPublic) {
            [values addObject:@"public"];
        }
        if (level & FoursquareBroadcastLevelTwitter) {
            [values addObject:@"twitter"];
        }
        if (level & FoursquareBroadcastLevelFacebook) {
            [values addObject:@"facebook"];
        }
    }
    [mutableParams setObject:[values componentsJoinedByString:@","] forKey:@"broadcast"];
    
    if (message) {
        [mutableParams setObject:message forKey:@"shout"];
    }
    
    request.isPostRequest = YES;
    request.params = [[mutableParams copy] autorelease];
    
    return request;
}

- (KGOFoursquareRequest *)queryCheckinsRequestWithDelegate:(id<KGOFoursquareRequestDelegate>)delegate
{
    KGOFoursquareRequest *request = [self requestWithDelegate:delegate];
    request.resourceName = @"users";
    request.resourceID = @"self";
    request.command = @"checkins";
    
    return request;
}

- (KGOFoursquareRequest *)herenowRequestWithDelegate:(id<KGOFoursquareRequestDelegate>)delegate
                                               venue:(NSString *)venue
{
    KGOFoursquareRequest *request = [self requestWithDelegate:delegate];
    
    request.resourceName = @"venues";
    request.resourceID = venue;
    request.command = @"herenow";
    
    return request;
}

- (KGOFoursquareRequest *)requestWithDelegate:(id<KGOFoursquareRequestDelegate>)delegate
{
    KGOFoursquareRequest *request = [[[KGOFoursquareRequest alloc] init] autorelease];
    request.delegate = delegate;
    if (_oauthToken) {
        request.params = [NSDictionary dictionaryWithObject:_oauthToken forKey:@"oauth_token"];
    }
    return request;
}

- (void)checkinVenue:(NSString *)venue delegate:(id<KGOFoursquareCheckinDelegate>)delegate
{
    KGOFoursquareRequest *request = [self checkinRequestWithDelegate:self
                                                               venue:venue
                                                      broadcastLevel:FoursquareBroadcastLevelPublic
                                                             message:nil];
    
    KGOFoursquareCheckinPair *pair = [[[KGOFoursquareCheckinPair alloc] init] autorelease];
    pair.delegate = delegate;
    pair.request = request;

    if (!_checkinQueue) {
        _checkinQueue = [[NSMutableArray alloc] init];
    }
    
    [_checkinQueue addObject:pair];
    
    [request connect];
}

- (void)checkUserStatusForVenue:(NSString *)venue delegate:(id<KGOFoursquareCheckinDelegate>)delegate
{
    KGOFoursquareRequest *request = [self queryCheckinsRequestWithDelegate:self];
    KGOFoursquareCheckinPair *pair = [[[KGOFoursquareCheckinPair alloc] init] autorelease];
    pair.delegate = delegate;
    pair.request = request;
    pair.userData = [NSDictionary dictionaryWithObjectsAndKeys:venue, @"venue", nil];
    
    if (!_checkinQueue) {
        _checkinQueue = [[NSMutableArray alloc] init];
    }
    
    [_checkinQueue addObject:pair];
    
    [request connect];
}

- (void)authorize
{
    if (!self.clientID) {
        NSLog(@"foursquare client ID not set");
    }
    
    NSString *internalScheme = [KGO_SHARED_APP_DELEGATE() defaultURLScheme];
    
    if (internalScheme) {
        self.redirectURI = [NSString stringWithFormat:@"%@://foursquare/authorize", internalScheme];
        NSString *urlString = [NSString stringWithFormat:@"https://foursquare.com/oauth2/authenticate"
                               "?client_id=%@"
                               "&response_type=code"
                               "&redirect_uri=%@"
                               "&display=touch",
                               self.clientID,
                               self.redirectURI];
        
        KGOWebViewController *webVC = [[[KGOWebViewController alloc] init] autorelease];
        webVC.requestURL = [NSURL URLWithString:urlString];
        webVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [KGO_SHARED_APP_DELEGATE() presentAppModalViewController:webVC animated:YES];
    }
}

- (void)requestOAuthToken
{
    if (!self.clientSecret) {
        NSLog(@"foursquare client secret not set");
    }
    
    NSString *urlString = [NSString stringWithFormat:@"https://foursquare.com/oauth2/access_token"
                           "?client_id=%@"
                           "&client_secret=%@"
                           "&grant_type=authorization_code"
                           "&redirect_uri=%@"
                           "&code=%@",
                           self.clientID,
                           self.clientSecret,
                           self.redirectURI,
                           self.authCode];
    
    _oauthRequest = [[self requestWithDelegate:self] retain];;
    [_oauthRequest requestFromURL:urlString];
}

- (void)logout
{
    [_oauthToken release];
    _oauthToken = nil;
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:FoursquareOAuthTokenKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)isLoggedIn
{
    if (!_oauthToken) {
        NSString *token = [[NSUserDefaults standardUserDefaults] stringForKey:FoursquareOAuthTokenKey];
        NSDate *date = [[NSUserDefaults standardUserDefaults] objectForKey:FoursquareOAuthExpirationDate];
        if (token && (!date || [date compare:[NSDate date]] != NSOrderedAscending)) {
            _oauthToken = [token retain];
        }
    }
    
    return _oauthToken != nil;
}


- (void)foursquareRequest:(KGOFoursquareRequest *)request didSucceedWithResponse:(NSDictionary *)response
{
    if (request == _oauthRequest) {
        [_oauthRequest release];
        _oauthRequest = nil;
        
        [_oauthToken release];
        _oauthToken = [[response stringForKey:@"access_token" nilIfEmpty:YES] retain];
        
        if (_oauthToken) {
            
            // TODO: foursquare currently doesn't expire access tokens,
            // but there is a "possibility in the future"
            // we need to verify the following code won't break anything if executed.
            id expires = [response objectForKey:@"expires"];
            if ([expires isKindOfClass:[NSString class]] || [expires isKindOfClass:[NSNumber class]]) {
                double expireTime = [expires doubleValue];
                NSDate *expireDate = [NSDate dateWithTimeIntervalSince1970:expireTime];
                [[NSUserDefaults standardUserDefaults] setObject:expireDate forKey:FoursquareOAuthExpirationDate];
            }
            
            [[NSUserDefaults standardUserDefaults] setObject:_oauthToken forKey:FoursquareOAuthTokenKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:FoursquareDidLoginNotification object:self];
            
            NSLog(@"received oauth token %@", _oauthToken);
        }
        
        [KGO_SHARED_APP_DELEGATE() dismissAppModalViewControllerAnimated:YES];

    } else {
        
        KGOFoursquareCheckinPair *currentPair = nil;
        for (KGOFoursquareCheckinPair *aPair in _checkinQueue) {
            if (aPair.request == request) {
                currentPair = aPair;
                break;
            }
        }

        if (currentPair) {
            if ([request.resourceName isEqualToString:@"venues"] && [request.command isEqualToString:@"herenow"]) {
                NSDictionary *hereNowDict = [response dictionaryForKey:@"hereNow"];
                NSNumber *count = [hereNowDict numberForKey:@"count"];
                NSArray *items = [hereNowDict arrayForKey:@"items"];
                for (NSDictionary *itemDict in items) {
                    NSDictionary *user = [itemDict dictionaryForKey:@"user"];
                }
                
            } else if ([request.resourceName isEqualToString:@"users"] && [request.command isEqualToString:@"checkins"]) {
                NSDictionary *checkinDict = [response dictionaryForKey:@"checkins"];
                NSArray *items = [checkinDict arrayForKey:@"items"];
                NSString *checkedInVenueID = nil;
                NSString *targetVenue = [currentPair.userData objectForKey:@"venue"];
                
                // TODO:
                if (!targetVenue) return;
                NSLog(@"%@", currentPair.userData);
                
                for (NSDictionary *itemDict in items) {
                    NSDictionary *venue = [itemDict dictionaryForKey:@"venue"];
                    NSString *venueID = [venue stringForKey:@"id" nilIfEmpty:YES];
                    NSLog(@"%@ %@", venueID, targetVenue);
                    if (venueID && targetVenue && [venueID isEqualToString:targetVenue]) {
                        checkedInVenueID = venueID;
                        break;
                    }
                }
                
                if ([currentPair.delegate respondsToSelector:@selector(venueCheckinStatusReceived:forVenue:)]) {
                    if (checkedInVenueID) {
                        [currentPair.delegate venueCheckinStatusReceived:YES forVenue:checkedInVenueID];

                    } else if (request.resourceID) {
                        [currentPair.delegate venueCheckinStatusReceived:NO forVenue:request.resourceID];
                    }
                }
                
            } else if ([request.resourceName isEqualToString:@"checkins"] && [request.command isEqualToString:@"add"]) {
                [currentPair.delegate venueCheckinDidSucceed:request.resourceID];
                
            }
            
            [_checkinQueue removeObject:currentPair];
        }

    }
}

- (void)foursquareRequest:(KGOFoursquareRequest *)request didFailWithError:(NSError *)error
{
    [_oauthRequest release];
    _oauthRequest = nil;
    
    NSLog(@"request failed with error: %@", [error description]);
}

- (void)disconnectRequestsForDelegate:(id<KGOFoursquareCheckinDelegate>)delegate
{
    NSMutableArray *removed = [NSMutableArray array];
    for (KGOFoursquareCheckinPair *aPair in _checkinQueue) {
        if (aPair.delegate == delegate) {
            aPair.delegate = nil;
            [removed addObject:aPair];
        }
    }
    for (KGOFoursquareCheckinPair *aPair in removed) {
        [_checkinQueue removeObject:aPair];
    }
}

- (void)dealloc
{
    if (_oauthRequest) {
        _oauthRequest.delegate = nil;
    }
    
    self.clientID = nil;
    self.clientSecret = nil;
    self.authCode = nil;
    self.redirectURI = nil;
    
    [_oauthToken release];
    [super dealloc];
}

@end
