#import "TwitterSearch.h"
#import "JSON.h"
#import "Foundation+KGOAdditions.h"

@implementation TwitterSearch

@synthesize delegate;

- (id)initWithDelegate:(id<TwitterSearchDelegate>)aDelegate {
    self = [super init];
    if (self) {
        self.delegate = aDelegate;
    }
    return self;
}

- (void)searchTwitterHashtag:(NSString *)hashtag {
    if (_connection || !hashtag.length) {
        return;
    }
    
    if (![hashtag characterAtIndex:0] == '#') {
        hashtag = [NSString stringWithFormat:@"#%@", hashtag];
    }
        
    DLog(@"searching twitter for %@", hashtag);
    
    NSString *urlString = [NSString stringWithFormat:@"http://search.twitter.com/search.json?q=%@&result_type=recent", hashtag];
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    _connection = [[ConnectionWrapper alloc] initWithDelegate:self];
    [_connection requestDataFromURL:[NSURL URLWithString:urlString] allowCachedResponse:NO];
}

- (void)connection:(ConnectionWrapper *)wrapper handleData:(NSData *)data {
    [_connection release];
    _connection = nil;
    
    SBJsonParser *parser = [[[SBJsonParser alloc] init] autorelease];
    id jsonObj = [parser objectWithData:data];
    if ([jsonObj isKindOfClass:[NSDictionary class]]) {
        NSArray *results = [jsonObj arrayForKey:@"results"];
        [self.delegate twitterSearch:self didReceiveSearchResults:results];
    }
}

- (void)connection:(ConnectionWrapper *)wrapper handleConnectionFailureWithError:(NSError *)error {
    [_connection release];
    _connection = nil;

    [self.delegate twitterSearch:self didFailWithError:error];
}

- (void)dealloc
{
    if (_connection) {
        [_connection cancel];
    }
    self.delegate = nil;
    [super dealloc];
}

@end
