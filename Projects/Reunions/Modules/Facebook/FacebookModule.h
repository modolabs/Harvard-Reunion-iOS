#import "MicroblogModule.h"


extern NSString * const OldDesktopGroupURL;
extern NSString * const NewDesktopGroupURL;

extern NSString * const FacebookGroupReceivedNotification;
extern NSString * const FacebookFeedDidUpdateNotification;

@interface FacebookModule : MicroblogModule {
    
    NSTimer *_statusPoller;
    NSArray *_latestFeedPosts;
    NSString *_gid;
    
    NSDate *_lastMessageDate;
    
    BOOL _requestingGroups;
    BOOL _memberOfFBGroupKnown;
    
    BOOL _shouldResume;
}

// code from http://developer.apple.com/library/ios/#qa/qa2010/qa1480.html
// TODO: move this to Common if we find this format used in other places
+ (NSDate *)dateFromRFC3339DateTimeString:(NSString *)string;

- (void)requestGroupOrStartPolling;
- (void)startPollingStatusUpdates;
- (void)stopPollingStatusUpdates;

- (void)requestStatusUpdates:(NSTimer *)aTimer;

- (void)didReceiveGroups:(id)result;
- (void)didReceiveFeed:(id)result;

- (void)facebookDidLogout:(NSNotification *)aNotification;
- (void)facebookDidLogin:(NSNotification *)aNotification;

@property(nonatomic, readonly) NSArray *latestFeedPosts;
@property(nonatomic, readonly) NSString *groupID;

- (BOOL)isMemberOfFBGroup;
- (BOOL)isMemberOfFBGroupKnown;

#pragma mark Bookmarking support
+ (NSString *)bookmarkKeyForMediaType:(NSString *)mediaType;
// Returns the current bookmarked state of the media object.
+ (BOOL)toggleBookmarkForMediaObjectWithID:(NSString *)mediaObjectID 
                                 mediaType:(NSString *)mediaType;
+ (NSDictionary *)bookmarksForMediaObjectsOfType:(NSString *)mediaType;
+ (BOOL)isMediaObjectWithIDBookmarked:(NSString *)mediaObjectID
                            mediaType:(NSString *)mediaType;

@end
