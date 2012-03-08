
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import "ReunionHomeModule.h"
#import "KGORequestManager.h"

#import "KGOSidebarFrameViewController.h"
#import "ReunionHomeViewController.h"
#import "ReunionSidebarFrameViewController.h"
#import "CoreDataManager.h"

NSString * const HomeScreenConfigPrefKey = @"homeScreenConfig";

@implementation ReunionHomeModule

#pragma mark Navigation

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        KGONavigationStyle style = [KGO_SHARED_APP_DELEGATE() navigationStyle];
        if (style == KGONavigationStylePortlet) {
            ReunionHomeViewController *homeVC = [[[ReunionHomeViewController alloc] init] autorelease];
            homeVC.homeModule = self;
            return homeVC;
        } else if (style == KGONavigationStyleTabletSidebar) {
            ReunionSidebarFrameViewController *homeVC = [[[ReunionSidebarFrameViewController alloc] init] autorelease];
            homeVC.homeModule = self;
            return homeVC;
        }
    }
    return [super modulePage:pageName params:params];
}

- (NSDictionary *)homeScreenConfig
{
    if (!_homeScreenConfig) {
        //_homeScreenConfig = [[[NSUserDefaults standardUserDefaults] objectForKey:HomeScreenConfigPrefKey] retain];
        //if (!_homeScreenConfig) {
            _request = [[KGORequestManager sharedManager] requestWithDelegate:self module:@"home" path:@"config" params:nil];
            [_request connect];
        //}
    }
    return _homeScreenConfig;
}

- (NSArray *)moduleOrder
{
    return [NSArray arrayWithObjects:
            @"schedule", @"map", @"photos", @"video", @"info", @"news", // @"connect",
            @"notes", @"attendees", nil];
}

- (void)dealloc {
    [_homeScreenConfig release];
    [super dealloc];
}

- (NSArray *)userDefaults
{
    return [NSArray arrayWithObjects:HomeScreenConfigPrefKey, nil];
}

#pragma mark - KGORequest

- (void)logout
{
    [_homeScreenConfig release];
    _homeScreenConfig = nil;
    
    //[[NSUserDefaults standardUserDefaults] removeObjectForKey:HomeScreenConfigPrefKey];
    //[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)requestWillTerminate:(KGORequest *)request
{
    _request = nil;
}

- (void)request:(KGORequest *)request didReceiveResult:(id)result
{
    NSLog(@"received home config: %@", result);
    
    NSString *reunionYear = [[[self reunionYear] copy] autorelease];
    
    [_homeScreenConfig release];
    _homeScreenConfig = [result retain];
    
    NSString *newReunionYear = [self reunionYear];
    if (reunionYear && ![reunionYear isEqualToString:newReunionYear]) {
        [[CoreDataManager sharedManager] deleteStore];
    }
    
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

- (BOOL)fbGroupIsOld
{
    id isOld = [_homeScreenConfig objectForKey:@"facebookGroupIsOld"];
    if ([isOld isKindOfClass:[NSString class]] || [isOld isKindOfClass:[NSNumber class]]) {
        return [isOld boolValue];
    }
    return NO;
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

- (NSString *)reunionYear
{
    return [_homeScreenConfig objectForKey:@"year"];
}

@end
