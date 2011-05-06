#import "FacebookModule.h"
#import "KGOSocialMediaController+FacebookAPI.h"
#import "KGOHomeScreenWidget.h"
#import "KGOTheme.h"
#import "UIKit+KGOAdditions.h"
#import "Foundation+KGOAdditions.h"
#import "FacebookUser.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "ReunionHomeModule.h"
#import "FacebookFeedViewController.h"
#import "KGORequestManager.h"

#define FACEBOOK_STATUS_POLL_FREQUENCY 60

static NSString * const FacebookGroupIsMemberKey = @"FacebookGroupMember";

NSString * const FacebookGroupReceivedNotification = @"FBGroupReceived";
NSString * const FacebookFeedDidUpdateNotification = @"FBFeedReceived";

@interface FacebookModule (Private)

- (void)setupPolling;
- (void)shutdownPolling;

@end

@implementation FacebookModule

// code from http://developer.apple.com/library/ios/#qa/qa2010/qa1480.html
+ (NSDate *)dateFromRFC3339DateTimeString:(NSString *)rfc3339DateTimeString {
    static NSDateFormatter *    sRFC3339DateFormatter;
    NSDate *                    date;
    
    // If the date formatters aren't already set up, do that now and cache them 
    // for subsequence reuse.
    
    if (sRFC3339DateFormatter == nil) {
        NSLocale *                  enUSPOSIXLocale;
        
        sRFC3339DateFormatter = [[NSDateFormatter alloc] init];
        assert(sRFC3339DateFormatter != nil);
        
        enUSPOSIXLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease];
        assert(enUSPOSIXLocale != nil);
        
        [sRFC3339DateFormatter setLocale:enUSPOSIXLocale];
        [sRFC3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ssZ"];
        [sRFC3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    }
    
    // Convert the RFC 3339 date time string to an NSDate.
    date = [sRFC3339DateFormatter dateFromString:rfc3339DateTimeString];
    return date;
}

- (NSArray *)applicationStateNotificationNames
{
    return [NSArray arrayWithObjects:FacebookDidLoginNotification, FacebookDidLogoutNotification, nil];
}

- (NSArray *)userDefaults
{
    return [NSArray arrayWithObjects:FacebookGroupKey, FacebookGroupIsMemberKey, FacebookGroupTitleKey, FacebookTokenKey, FacebookTokenExpirationSetting, FacebookUsernameKey, @"photo_bookmarks", @"video_bookmarks", nil];
}

#pragma mark polling

- (void)setupPolling {
    NSLog(@"setting up polling...");
    if (![[KGOSocialMediaController facebookService] isSignedIn]) {
        NSLog(@"waiting for facebook to log in...");
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(facebookDidLogin:)
                                                     name:FacebookDidLoginNotification
                                                   object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(facebookDidLogout:)
                                                     name:FacebookDidLogoutNotification
                                                   object:nil];
        
        [self requestGroupOrStartPolling];
    }
}

- (void)shutdownPolling {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopPollingStatusUpdates];
}

- (void)startPollingStatusUpdates {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hideChatBubble:)
                                                 name:TwitterStatusDidUpdateNotification
                                               object:nil];
    
    if (!_statusPoller) {
        NSLog(@"scheduling timer...");
        NSTimeInterval interval = FACEBOOK_STATUS_POLL_FREQUENCY;
        _statusPoller = [[NSTimer timerWithTimeInterval:interval
                                                 target:self
                                               selector:@selector(requestStatusUpdates:)
                                               userInfo:nil
                                                repeats:YES] retain];
        [[NSRunLoop currentRunLoop] addTimer:_statusPoller forMode:NSDefaultRunLoopMode];
    }
}

- (void)stopPollingStatusUpdates {
    if (_statusPoller) {
        [_statusPoller invalidate];
        [_statusPoller release];
        _statusPoller = nil;
    }
}

- (void)requestStatusUpdates:(NSTimer *)aTimer {
    DLog(@"requesting facebook status update");
    
    NSString *feedPath = [NSString stringWithFormat:@"%@/feed?limit=1000", _gid];
    [[KGOSocialMediaController facebookService] requestFacebookGraphPath:feedPath
                                                                receiver:self
                                                                callback:@selector(didReceiveFeed:)];
    
    
}

#pragma mark facebook connection

- (void)requestGroupOrStartPolling {
    _lastMessageDate = [[NSDate distantPast] retain];
    if (!_gid || ![self isMemberOfFBGroup]) {
        if (!_requestingGroups) {
            _requestingGroups = [[KGOSocialMediaController facebookService] requestFacebookGraphPath:@"me/groups"
                                                                                             receiver:self
                                                                                             callback:@selector(didReceiveGroups:)];
        }
    } else {
        [self startPollingStatusUpdates];
    }
}

- (void)facebookDidLogin:(NSNotification *)aNotification
{
    NSLog(@"facebook logged in");
    [self requestGroupOrStartPolling];
}

- (void)facebookDidLogout:(NSNotification *)aNotification
{
    [_latestFeedPosts release];
    _latestFeedPosts = nil;
    
    [self shutdownPolling];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:FacebookGroupIsMemberKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:FacebookGroupKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(facebookDidLogin:)
                                                 name:FacebookDidLoginNotification
                                               object:nil];
}

- (NSString *)groupID {
    return _gid;
}

- (void)didReceiveGroups:(id)result {
    _requestingGroups = NO;
    NSArray *data = [result arrayForKey:@"data"];
    //BOOL foundGroup = NO;
    DLog(@"%@", data);
    
    for (id aGroup in data) {
        // TODO: get group names from server
        if ([[aGroup objectForKey:@"id"] isEqualToString:_gid]) {
            //foundGroup = YES;
            [[NSUserDefaults standardUserDefaults] setObject:_gid forKey:FacebookGroupIsMemberKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:FacebookGroupReceivedNotification object:self];

            [self startPollingStatusUpdates];
        }
    }
}

- (NSArray *)latestFeedPosts {
    return _latestFeedPosts;
}

- (void)didReceiveFeed:(id)result {
    NSArray *data = [result arrayForKey:@"data"];
    if (data) {
        [_latestFeedPosts release];
        _latestFeedPosts = [data retain];
        
        for (NSDictionary *aPost in _latestFeedPosts) {
            NSString *type = [aPost stringForKey:@"type" nilIfEmpty:YES];
            if ([type isEqualToString:@"status"]) {
                NSString *message = [aPost stringForKey:@"message" nilIfEmpty:YES];
                
                NSDictionary *from = [aPost dictionaryForKey:@"from"];
                FacebookUser *user = [FacebookUser userWithDictionary:from];
                
                NSDate *lastUpdate = nil;
                NSString *dateString = [aPost stringForKey:@"updated_time" nilIfEmpty:YES];
                if (dateString) {
                    lastUpdate = [FacebookModule dateFromRFC3339DateTimeString:dateString];
                }
                
                // TODO: if we confirm that this is later than the twitter update, hide twitter's chatbubble
                if (lastUpdate && [lastUpdate compare:_lastMessageDate] == NSOrderedDescending) {
                    [_lastMessageDate release];
                    _lastMessageDate = [lastUpdate retain];

                    self.chatBubble.hidden = NO;
                    self.chatBubbleSubtitleLabel.text = [NSString stringWithFormat:
                                                         @"%@ %@", user.name,
                                                         [_lastMessageDate agoString]];
                    self.chatBubbleThumbnail.imageData = nil;
                    self.chatBubbleThumbnail.imageURL = [[KGOSocialMediaController facebookService] imageURLForGraphObject:user.identifier];
                    [self.chatBubbleThumbnail loadImage];
                    self.chatBubbleTitleLabel.text = message;
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:FacebookStatusDidUpdateNotification object:nil];

                    break;
                }
            }
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:FacebookFeedDidUpdateNotification object:self];
    }
}

#pragma mark -

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [self stopPollingStatusUpdates]; // invalidates and releases NSTimer object
    [_latestFeedPosts release];
    [_gid release];
    [_lastMessageDate release];
    [super dealloc];
}

- (id)initWithDictionary:(NSDictionary *)moduleDict {
    self = [super initWithDictionary:moduleDict];
    if (self) {
        self.buttonImage = [UIImage imageWithPathName:@"modules/facebook/button-facebook.png"];
        
        KGONavigationStyle navStyle = [KGO_SHARED_APP_DELEGATE() navigationStyle];
        if (navStyle == KGONavigationStyleTabletSidebar) {
            self.chatBubbleCaratOffset = 0.75;
        } else {
            self.chatBubbleCaratOffset = 0.25;
        }
    }
    return self;
}

- (NSArray *)objectModelNames {
    return [NSArray arrayWithObject:@"FacebookModel"];
}

// called when kurogo logs in
- (void)didLogin:(NSNotification *)aNotification
{
    ReunionHomeModule *homeModule = (ReunionHomeModule *)[KGO_SHARED_APP_DELEGATE() moduleForTag:@"home"];
    DLog(@"fbGroupName: %@", [homeModule fbGroupName]);
    DLog(@"fbGroupID: %@", [homeModule fbGroupID]);
    self.labelText = [homeModule fbGroupName];
    _gid = [[homeModule fbGroupID] retain];
    if (_gid) {
        [[NSUserDefaults standardUserDefaults] setObject:[homeModule fbGroupName] forKey:FacebookGroupTitleKey];
        [[NSUserDefaults standardUserDefaults] setObject:_gid forKey:FacebookGroupKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self setupPolling];
    }
}

- (BOOL)isMemberOfFBGroup
{
    NSString *belongingGroup = [[NSUserDefaults standardUserDefaults] objectForKey:FacebookGroupIsMemberKey];
    return [belongingGroup isEqualToString:_gid];
}

#pragma mark -

/*
- (void)launch {
    [super launch];
    [[KGOSocialMediaController sharedController] startupFacebook];
    [self setupPolling];
}


- (void)terminate {
    [super terminate];
    [[KGOSocialMediaController sharedController] shutdownFacebook];
    [self shutdownPolling];
}
*/
- (void)applicationDidFinishLaunching {
    [[KGOSocialMediaController facebookService] startup];
    _gid = [[[NSUserDefaults standardUserDefaults] objectForKey:FacebookGroupKey] retain];
    
    [self setupPolling];
}

- (void)applicationWillTerminate {
    [[KGOSocialMediaController facebookService] shutdown];
    [self shutdownPolling];
}

- (void)applicationDidEnterBackground {
    [self shutdownPolling];
}

- (void)applicationWillEnterForeground {
    [self setupPolling];
}

#pragma mark View on home screen
/*
- (KGOHomeScreenWidget *)buttonWidget {
    KGOHomeScreenWidget *widget = [super buttonWidget];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        widget.gravity = KGOLayoutGravityBottomRight;
    }
    return widget;
}
*/


- (Class)feedViewControllerClass
{
    return [FacebookFeedViewController class];
}

- (NSString *)feedViewControllerTitle
{
    return @"Facebook Group";
}

- (void)willShowModalFeedController
{
    [[NSNotificationCenter defaultCenter] postNotificationName:FacebookStatusDidUpdateNotification object:self];
    self.chatBubble.hidden = NO;
}

#pragma mark Social media controller

- (NSSet *)socialMediaTypes {
    return [NSSet setWithObject:KGOSocialMediaTypeFacebook];
}

- (NSDictionary *)userInfoForSocialMediaType:(NSString *)mediaType {
    if ([mediaType isEqualToString:KGOSocialMediaTypeFacebook]) {
        return [NSDictionary dictionaryWithObject:[NSArray arrayWithObjects:
                                                   @"read_stream",
                                                   //@"offline_access",
                                                   @"user_groups",
                                                   nil]
                                           forKey:@"permissions"];
    }
    return nil;
}

#pragma mark Bookmarking support

+ (BOOL)toggleBookmarkForMediaObjectWithID:(NSString *)mediaObjectID 
                                 mediaType:(NSString *)mediaType {
    NSMutableDictionary *bookmarks = 
    [[[[self class] bookmarksForMediaObjectsOfType:mediaType] 
      mutableCopy] autorelease];
    NSString *bookmarksKey = [[self class] bookmarkKeyForMediaType:mediaType];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:bookmarksKey];    
    BOOL bookmarked = [[bookmarks objectForKey:mediaObjectID] boolValue];
    bookmarked = !bookmarked;
    [bookmarks setObject:[NSNumber numberWithBool:bookmarked] 
                  forKey:mediaObjectID];
    
    [[NSUserDefaults standardUserDefaults] 
     setObject:bookmarks forKey:bookmarksKey];
    return bookmarked;
}

+ (NSDictionary *)bookmarksForMediaObjectsOfType:(NSString *)mediaType {
    NSString *key = [[self class] bookmarkKeyForMediaType:mediaType];
    NSDictionary *bookmarks = 
    [[NSUserDefaults standardUserDefaults] dictionaryForKey:key];
    if (!bookmarks) {
        bookmarks = [NSDictionary dictionary];
        [[NSUserDefaults standardUserDefaults] setObject:bookmarks forKey:key];
    }
    return bookmarks;
}

+ (NSString *)bookmarkKeyForMediaType:(NSString *)mediaType {
    return [NSString stringWithFormat:@"%@_bookmarks", mediaType];
}

+ (BOOL)isMediaObjectWithIDBookmarked:(NSString *)mediaObjectID
                            mediaType:(NSString *)mediaType {
    NSDictionary *bookmarks = 
    [[self class] bookmarksForMediaObjectsOfType:mediaType];
    return [[bookmarks objectForKey:mediaObjectID] boolValue];
}

@end
