//
//  ConnectModule.m
//

#import "ConnectModule.h"
#import "ConnectViewController.h"

@implementation ConnectModule

#pragma mark KGOModule

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    return [[[ConnectViewController alloc] init] autorelease];
             //initWithFrame:[UIApplication sharedApplication].keyWindow.frame] autorelease];
}

@end
