#import "AboutModule.h"
#import "AboutTableViewController.h"

@implementation AboutModule

- (id)initWithDictionary:(NSDictionary *)moduleDict {
    self = [super initWithDictionary:moduleDict];
    if (self) {
        
        NSLog(@"about: %@", moduleDict);
    }
    return self;
}

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        AboutTableViewController *aboutVC = [[[AboutTableViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
        aboutVC.moduleTag = self.tag;
        aboutVC.title = self.shortName;
        vc = aboutVC;
    }
    return vc;
}

- (NSArray *)userDefaults
{
    return [NSArray arrayWithObjects:AboutParagraphsPrefKey, AboutSectionsPrefKey, nil];
}

@end
