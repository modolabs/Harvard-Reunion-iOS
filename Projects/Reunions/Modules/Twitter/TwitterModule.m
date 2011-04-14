#import "TwitterModule.h"
#import "KGOSocialMediaController+FacebookAPI.h"
#import "KGOHomeScreenWidget.h"
#import "KGOTheme.h"
#import "UIKit+KGOAdditions.h"
#import "Foundation+KGOAdditions.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "TwitterFeedViewController.h"
#import "ReunionHomeModule.h"
#import "MITThumbnailView.h"
#import "KGOHomeScreenViewController.h"
#import <QuartzCore/QuartzCore.h>

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
        
        _hashTag = [[[NSUserDefaults standardUserDefaults] stringForKey:TwitterHashTagKey] retain];
        if (_hashTag) {
            self.labelText = _hashTag;
        }
        
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

- (void)didLogin:(NSNotification *)aNotification
{
    ReunionHomeModule *homeModule = (ReunionHomeModule *)[KGO_SHARED_APP_DELEGATE() moduleForTag:@"home"];
    self.labelText = [homeModule twitterHashTag];
    _hashTag = [[homeModule twitterHashTag] retain];
    
    [[NSUserDefaults standardUserDefaults] setObject:_hashTag forKey:TwitterHashTagKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// TODO: possibly move this into MicroblogModule
- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params
{
    UIViewController *vc = nil;
    if ([KGO_SHARED_APP_DELEGATE() navigationStyle] != KGONavigationStyleTabletSidebar) {
        if ([pageName isEqualToString:LocalPathPageNameHome]) {
            vc = [[[TwitterFeedViewController alloc] initWithStyle:UITableViewStylePlain] autorelease];
        }
    } else {
        if (_modalTwitterController) {
            return nil;
        }
        
        // circumvent the app delegate and present our own thing
        UIViewController *homescreen = [KGO_SHARED_APP_DELEGATE() homescreen];
        
        TwitterFeedViewController *twitterVC = [[[TwitterFeedViewController alloc] initWithStyle:UITableViewStylePlain] autorelease];
        _modalTwitterController = [[UINavigationController alloc] initWithRootViewController:twitterVC];
        
        twitterVC.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                                    target:self
                                                                                                    action:@selector(hideModalTwitterController:)] autorelease];

        CGRect frame = self.chatBubble.frame;
        frame.size.height -= 15;
        _modalTwitterController.view.frame = frame;
        
        twitterVC.view.layer.cornerRadius = 6;
        _modalTwitterController.view.layer.cornerRadius = 6;
        
        CGRect screenFrame = [(KGOHomeScreenViewController *)homescreen springboardFrame];
        CGFloat bottom = frame.origin.y + frame.size.height;
        CGFloat top = 48;
        frame = CGRectMake(10, top, screenFrame.size.width - 20, bottom - top);
        
        _scrim = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenFrame.size.width, screenFrame.size.height)];
        _scrim.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        _scrim.alpha = 0;
        
        [homescreen.view addSubview:_scrim];
        [homescreen.view addSubview:_modalTwitterController.view];
        
        
        UIBarButtonItem *item = twitterVC.navigationItem.rightBarButtonItem;
        twitterVC.navigationItem.rightBarButtonItem = nil;
        
        __block TwitterFeedViewController *blockTwitterVC = twitterVC;
        [UIView animateWithDuration:0.4 animations:^(void) {
            _modalTwitterController.view.frame = frame;
            _scrim.alpha = 1;
        } completion:^(BOOL finished) {
            blockTwitterVC.navigationItem.rightBarButtonItem = item;
        }];
        
        [UIView animateWithDuration:0.4 animations:^(void) {
        }];
        
    }
    return vc;
}

- (void)hideModalTwitterController:(id)sender
{
    CGRect frame = self.chatBubble.frame;
    frame.size.height -= 15;
    
    [UIView animateWithDuration:0.4 animations:^(void) {
        _modalTwitterController.view.frame = frame;
        _scrim.alpha = 0;

    } completion:^(BOOL finished) {
        [_scrim removeFromSuperview];
        [_scrim release];
        _scrim = nil;
        
        [_modalTwitterController.view removeFromSuperview];
        [_modalTwitterController release];
        _modalTwitterController = nil;
    }];
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

- (void)startPollingStatusUpdates
{
    [[KGOSocialMediaController sharedController] startupTwitter];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hideChatBubble:)
                                                 name:FacebookStatusDidUpdateNotification
                                               object:nil];
    
    if (!_twitterSearch) {
         // avoid warning about ConnectionWrapper which has the same signature
        _twitterSearch = [(TwitterSearch *)[TwitterSearch alloc] initWithDelegate:self];
    }
    
    [self requestStatusUpdates:nil];
    
    if (!_statusPoller) {
        DLog(@"scheduling twitter timer...");
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
    if (_hashTag) {
        [_twitterSearch searchTwitterHashtag:_hashTag];
    }
}

- (void)twitterSearch:(TwitterSearch *)twitterSearch didReceiveSearchResults:(NSArray *)results {
    if (results.count) {
        [_latestTweets release];
        _latestTweets = [results retain];
        
        NSDictionary *aTweet = [_latestTweets objectAtIndex:0];
        DLog(@"received tweet %@", aTweet);
        NSString *title = [aTweet stringForKey:@"text" nilIfEmpty:YES];
        NSString *user = [aTweet stringForKey:@"from_user" nilIfEmpty:YES];
        NSString *dateString = [aTweet stringForKey:@"created_at" nilIfEmpty:YES];
        NSString *imageURL = [aTweet stringForKey:@"profile_image_url" nilIfEmpty:YES];
        NSDate *date = [[self twitterDateFormatter] dateFromString:dateString];
        
        if (!_lastUpdate || [_lastUpdate compare:date] == NSOrderedAscending) {
            [_lastUpdate release];
            _lastUpdate = [date retain];
            self.chatBubble.hidden = NO;
            self.chatBubbleTitleLabel.text = title;
            self.chatBubbleSubtitleLabel.text = [NSString stringWithFormat:@"%@ at %@", user, [date agoString]];
            self.chatBubbleThumbnail.imageURL = imageURL;
            [self.chatBubbleThumbnail loadImage];
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

- (void)dealloc
{
    // TODO: release other stuff
    [super dealloc];
}

@end
