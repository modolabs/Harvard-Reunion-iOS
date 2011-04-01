#import "KGOFoursquareEngine.h"
#import "JSON.h"
#import "KGOWebViewController.h"
#import "KGOAppDelegate.h"
#import "Foundation+KGOAdditions.h"

static NSString * const FoursquareBaseURL = @"https://api.foursquare.com/v2/";

@implementation KGOFoursquareRequest

@synthesize delegate, resourceName, resourceID, command, params;

- (void)checkinToVenueID:(NSString *)venueID broadcastLevel:(NSUInteger)level message:(NSString *)message
{
    self.resourceName = @"checkins";
    self.command = @"add";
    
    NSMutableDictionary *mutableParams = [[self.params mutableCopy] autorelease];
    
    [mutableParams setObject:venueID forKey:@"venueId"];
    
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

    _isPostRequest = YES;
    _postParams = [mutableParams copy];

    [self requestFromURL:[self fullURLString]];
}

- (void)requestCheckinsForVenueID:(NSString *)venueID
{
    self.resourceName = @"venues";
    self.resourceID = venueID;
    self.command = @"herenow";
    
    [self requestFromURL:[self fullURLString]];
}

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

- (void)requestFromURL:(NSString *)urlString
{
    if (_connection) {
        return;
    }
    
    NSLog(@"foursquare: requesting from %@", urlString);
    
    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]
                                                                 cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                             timeoutInterval:30] autorelease];
    
    if (_isPostRequest) {
        [request setHTTPMethod:@"POST"];
        _isPostRequest = NO;
    }
    
    if (_postParams) {
        NSError *error = nil;
        [request setHTTPBody:[NSPropertyListSerialization dataWithPropertyList:_postParams
                                                                        format:NSPropertyListBinaryFormat_v1_0
                                                                       options:0
                                                                         error:&error]];
        [_postParams release];
        _postParams = nil;

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
        NSLog(@"%@", [result description]);
        [self.delegate foursquareRequest:self didSucceedWithResponse:result];
    } else {
        NSLog(@"received result that was not a dictionary: %@", [result description]);
    }
}

@end




@implementation KGOFoursquareEngine

static NSString * const FoursquareOAuthTokenKey = @"4squareToken";

@synthesize authCode, redirectURI, clientID, clientSecret;

- (KGOFoursquareRequest *)requestWithDelegate:(id<KGOFoursquareRequestDelegate>)delegate
{
    KGOFoursquareRequest *request = [[[KGOFoursquareRequest alloc] init] autorelease];
    request.delegate = delegate;
    if (_oauthToken) {
        request.params = [NSDictionary dictionaryWithObject:_oauthToken forKey:@"oauth_token"];
    }
    return request;
}

- (void)authorize
{
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
    
    _oauthRequest = [self requestWithDelegate:self];
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
        if (token) {
            _oauthToken = [token retain];
        }
    }
    
    return _oauthToken != nil;
}


- (void)foursquareRequest:(KGOFoursquareRequest *)request didSucceedWithResponse:(NSDictionary *)response
{
    [_oauthRequest release];
    _oauthRequest = nil;
    
    [_oauthToken release];
    _oauthToken = [[response stringForKey:@"access_token" nilIfEmpty:YES] retain];
    
    if (_oauthToken) {
        [[NSUserDefaults standardUserDefaults] setObject:_oauthToken forKey:FoursquareOAuthTokenKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        NSLog(@"received oauth token %@", _oauthToken);
    }
    
    [KGO_SHARED_APP_DELEGATE() dismissAppModalViewControllerAnimated:YES];
}

- (void)foursquareRequest:(KGOFoursquareRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"request failed with error: %@", [error description]);
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
