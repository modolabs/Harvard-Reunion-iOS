#import "TwitterModule.h"
#import "KGOSocialMediaController+FacebookAPI.h"
#import "KGOHomeScreenWidget.h"
#import "KGOTheme.h"
#import "UIKit+KGOAdditions.h"
#import "Foundation+KGOAdditions.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "TwitterFeedViewController.h"

#define TWITTER_BUTTON_WIDTH_IPHONE 120
#define TWITTER_BUTTON_HEIGHT_IPHONE 51

#define TWITTER_BUTTON_WIDTH_IPAD 75
#define TWITTER_BUTTON_HEIGHT_IPAD 100

#define TWITTER_STATUS_POLL_FREQUENCY 60

NSString * const TwitterFeedDidUpdateNotification = @"twitterUpdated";

@implementation TwitterModule

- (NSDateFormatter *)twitterDateFormatter {
    if (!_twitterDateFormatter) {
        _twitterDateFormatter = [[NSDateFormatter alloc] init];
        NSLocale *enUSPOSIXLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease];
        [_twitterDateFormatter setLocale:enUSPOSIXLocale];
        [_twitterDateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss Z"];        
    }
    return _twitterDateFormatter;
}

- (NSArray *)latestTweets {
    return _latestTweets;
}

- (id)initWithDictionary:(NSDictionary *)moduleDict {
    self = [super initWithDictionary:moduleDict];
    if (self) {
        self.buttonImage = [UIImage imageWithPathName:@"modules/twitter/button-twitter.png"];
        self.labelText = @"#hr14";
        
        // TODO: we are cheating here as we know where twitter and facebook will
        // be placed on the home screen under each condition.  if/when there is
        // a home screen notification module/widget for Kurogo, replace the chat
        // bubble with that
        KGOAppDelegate *appDelegate = KGO_SHARED_APP_DELEGATE();
        KGONavigationStyle navStyle = [appDelegate navigationStyle];
        if (navStyle == KGONavigationStyleTabletSidebar) {
            self.chatBubbleCaratOffset = 0.25;
        } else {
            self.chatBubbleCaratOffset = 0.75;
        }
    }
    return self;
}

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        vc = [[[TwitterFeedViewController alloc] initWithStyle:UITableViewStylePlain] autorelease];
    }
    return vc;
}

- (void)applicationDidFinishLaunching {
    [self startPollingStatusUpdates];
}

- (void)applicationWillTerminate {
    [self stopPollingStatusUpdates];
}

- (void)applicationDidEnterBackground {
    [self stopPollingStatusUpdates];
}

- (void)applicationWillEnterForeground {
    [self startPollingStatusUpdates];
}

#pragma mark polling

- (void)startPollingStatusUpdates {
    [[KGOSocialMediaController sharedController] startupTwitter];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hideChatBubble:)
                                                 name:FacebookStatusDidUpdateNotification
                                               object:nil];
    [self requestStatusUpdates:nil];
    
    if (!_twitterSearch) {
         // avoid warning about ConnectionWrapper which has the same signature
        _twitterSearch = [(TwitterSearch *)[TwitterSearch alloc] initWithDelegate:self];
    }
    
    if (!_statusPoller) {
        NSLog(@"scheduling timer...");
        NSTimeInterval interval = TWITTER_STATUS_POLL_FREQUENCY;
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
    if (_twitterSearch) {
        _twitterSearch.delegate = nil;
        [_twitterSearch release];
        _twitterSearch = nil;
    }

    [[KGOSocialMediaController sharedController] shutdownTwitter];
}

- (void)requestStatusUpdates:(NSTimer *)aTimer {
    [_twitterSearch searchTwitterHashtag:@"sxsw"];
}

- (void)twitterSearch:(TwitterSearch *)twitterSearch didReceiveSearchResults:(NSArray *)results {
    if (results.count) {
        [_latestTweets release];
        _latestTweets = [results retain];
        
        NSDictionary *aTweet = [_latestTweets objectAtIndex:0];
        NSLog(@"%@", aTweet);
        NSString *title = [aTweet stringForKey:@"text" nilIfEmpty:YES];
        NSString *user = [aTweet stringForKey:@"from_user" nilIfEmpty:YES];
        NSString *dateString = [aTweet stringForKey:@"created_at" nilIfEmpty:YES];
        NSDate *date = [[self twitterDateFormatter] dateFromString:dateString];
        
        if (!_lastUpdate || [_lastUpdate compare:date] == NSOrderedAscending) {
            [_lastUpdate release];
            _lastUpdate = [date retain];
            self.chatBubble.hidden = NO;
            self.chatBubbleTitleLabel.text = title;
            self.chatBubbleSubtitleLabel.text = [NSString stringWithFormat:@"%@ at %@", user, [date agoString]];
            [[NSNotificationCenter defaultCenter] postNotificationName:TwitterStatusDidUpdateNotification object:nil];
        }
    }
}

- (void)twitterSearch:(TwitterSearch *)twitterSearch didFailWithError:(NSError *)error {
    ;
}

#pragma mark View on home screen


#pragma mark Social media controller

- (NSSet *)socialMediaTypes {
    return [NSSet setWithObject:KGOSocialMediaTypeTwitter];
}

@end
