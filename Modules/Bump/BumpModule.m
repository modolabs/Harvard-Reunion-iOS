//
//  BumpModule.m
//  Universitas
//

#import "BumpModule.h"
#import "BumpViewController.h"

@implementation BumpModule

#pragma mark KGOModule

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    return [[[BumpViewController alloc] init] autorelease];
             //initWithFrame:[UIApplication sharedApplication].keyWindow.frame] autorelease];
}

@end
