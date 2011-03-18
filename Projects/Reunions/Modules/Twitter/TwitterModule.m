#import "TwitterModule.h"
#import "KGOSocialMediaController+FacebookAPI.h"
#import "KGOHomeScreenWidget.h"
#import "KGOTheme.h"
#import "UIKit+KGOAdditions.h"
#import "Foundation+KGOAdditions.h"
#import "KGOAppDelegate+ModuleAdditions.h"

#define TWITTER_BUTTON_WIDTH_IPHONE 120
#define TWITTER_BUTTON_HEIGHT_IPHONE 51

#define TWITTER_BUTTON_WIDTH_IPAD 75
#define TWITTER_BUTTON_HEIGHT_IPAD 100

@implementation TwitterModule

- (id)initWithDictionary:(NSDictionary *)moduleDict {
    self = [super initWithDictionary:moduleDict];
    if (self) {
        self.buttonImage = [UIImage imageWithPathName:@"modules/twitter/button-twitter.png"];
        self.labelText = @"#hr14";
        
        // TODO: we are cheating here as we know where twitter and facebook will
        // be placed on the home screen under each condition.  if/when there is
        // a home screen notification module/widget for Kurogo, replace the chat
        // bubble with that
        KGOAppDelegate *appDelegate = (KGOAppDelegate *)[[UIApplication sharedApplication] delegate];
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
    return nil;
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
        NSTimeInterval interval = 15;
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
        NSString *date = [aTweet stringForKey:@"created_at" nilIfEmpty:YES];
        
        if (![_lastUpdate isEqualToString:date]) {
            [_lastUpdate release];
            _lastUpdate = [date retain];
            self.chatBubble.hidden = NO;
            self.chatBubbleTitleLabel.text = title;
            self.chatBubbleSubtitleLabel.text = [NSString stringWithFormat:@"%@ at %@", user, date];
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
