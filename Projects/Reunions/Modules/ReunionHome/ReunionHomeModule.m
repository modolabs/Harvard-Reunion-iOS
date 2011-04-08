#import "ReunionHomeModule.h"
#import "KGORequestManager.h"

#import "KGOSidebarFrameViewController.h"
#import "ReunionHomeViewController.h"

NSString * const HomeScreenConfigPrefKey = @"homeScreenConfig";

@implementation ReunionHomeModule

/*
{
    "title":"Harvard Class of 2001",
    "number":"10",
    "startDate":"2011-05-26",
    "endDate":"2011-05-29",
    "classWebsite":"http:\/\/classes.harvard.edu\/college\/2001",
    "calendarURL":"http:\/\/www.trumba.com\/calendars\/2011-reunions-test-2001.ics",
    "facebookGroupName":"Harvard Class of '01",
    "facebookGroupId":"151803971548613",
    "facebookGroupIsOld":"0",
    "twitterHashtag":"#testhvd01"
}
*/

#pragma mark Navigation

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        KGONavigationStyle style = [KGO_SHARED_APP_DELEGATE() navigationStyle];
        if (style == KGONavigationStylePortlet) {
            ReunionHomeViewController *homeVC = [[[ReunionHomeViewController alloc] init] autorelease];
            homeVC.homeModule = self;
            return homeVC;
        }
    }
    return [super modulePage:pageName params:params];
}

- (NSDictionary *)homeScreenConfig
{
    if (!_homeScreenConfig) {
        _homeScreenConfig = [[[NSUserDefaults standardUserDefaults] objectForKey:HomeScreenConfigPrefKey] retain];
        if (!_homeScreenConfig) {
            _request = [[KGORequestManager sharedManager] requestWithDelegate:self module:@"home" path:@"config" params:nil];
            [_request connect];
        }
    }
    return _homeScreenConfig;
}


- (void)dealloc {
    [_homeScreenConfig release];
    [super dealloc];
}

#pragma mark - KGORequest

- (void)requestWillTerminate:(KGORequest *)request
{
    _request = nil;
}

- (void)request:(KGORequest *)request didReceiveResult:(id)result
{
    NSLog(@"received home config: %@", result);
    
    [_homeScreenConfig release];
    _homeScreenConfig = [result retain];
    
    // TODO: only save to defaults if we have persistent logins
    //[[NSUserDefaults standardUserDefaults] setObject:result forKey:HomeScreenConfigPrefKey];
    //[[NSUserDefaults standardUserDefaults] synchronize];

    // this will trigger the home screen to stop loading
    [[NSNotificationCenter defaultCenter] postNotificationName:KGODidLoginNotification object:nil];
}

#pragma mark -

- (NSString *)fbGroupID
{
    return [_homeScreenConfig objectForKey:@"facebookGroupId"];
}

- (NSString *)fbGroupName
{
    return [_homeScreenConfig objectForKey:@"facebookGroupName"];
}

- (NSString *)twitterHashTag
{
    return [_homeScreenConfig objectForKey:@"twitterHashtag"];
}

- (NSString *)reunionName
{
    return [_homeScreenConfig objectForKey:@"title"];
}

- (NSString *)reunionDateString
{
    NSString *dateString = nil;
    
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateFormat:@"YYYY-MM-dd"];
    NSDate *startDate = [formatter dateFromString:[_homeScreenConfig objectForKey:@"startDate"]];
    NSDate *endDate = [formatter dateFromString:[_homeScreenConfig objectForKey:@"endDate"]];
    
    NSDateComponents *startComps = [[NSCalendar currentCalendar] components:NSMonthCalendarUnit fromDate:startDate];
    NSDateComponents *endComps = [[NSCalendar currentCalendar] components:NSMonthCalendarUnit fromDate:endDate];
    if ([startComps month] == [endComps month]) {
        [formatter setDateFormat:@"MMM"];
        NSString *month = [formatter stringFromDate:startDate];
        [formatter setDateFormat:@"dd"];
        dateString = [NSString stringWithFormat:@"%@ %@-%@",
                      month, [formatter stringFromDate:startDate], [formatter stringFromDate:endDate]];
        
    } else {
        [formatter setDateFormat:@"MMM dd"];
        dateString = [NSString stringWithFormat:@"%@-%@", [formatter stringFromDate:startDate], [formatter stringFromDate:endDate]];
    }
    
    return dateString;
}

- (NSString *)reunionNumber
{
    return [_homeScreenConfig objectForKey:@"number"];
}

@end
