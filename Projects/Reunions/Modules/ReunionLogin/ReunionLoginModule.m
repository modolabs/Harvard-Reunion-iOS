#import "ReunionLoginModule.h"
#import "KGOHomeScreenWidget.h"
#import "KGOHomeScreenViewController.h"
#import "KGOTheme.h"
#import "UIKit+KGOAdditions.h"
#import "ReunionHomeModule.h"
#import "KGOAppDelegate+ModuleAdditions.h"

@implementation ReunionLoginModule

- (UIView *)ribbonWidget
{
    ReunionHomeModule *homeModule = (ReunionHomeModule *)[KGO_SHARED_APP_DELEGATE() moduleForTag:@"home"];
    
    KGONavigationStyle navStyle = [KGO_SHARED_APP_DELEGATE() navigationStyle];
    if (navStyle == KGONavigationStylePortlet) {
        UIImage *image = [UIImage imageWithPathName:@"modules/home/ribbon"];
        UIImageView *imageView = [[[UIImageView alloc] initWithImage:image] autorelease];
        
        NSString *text = [homeModule reunionNumber];
        UIFont *font = [UIFont fontWithName:@"Georgia" size:38];
        CGSize size = [text sizeWithFont:font];

        CGFloat x = 10;
        UILabel *yearLabel = [[[UILabel alloc] initWithFrame:CGRectMake(x, 20, size.width, size.height)] autorelease];
        yearLabel.text = text;
        yearLabel.font = font;
        yearLabel.backgroundColor = [UIColor clearColor];
        x += size.width;
        CGFloat y = 20 + size.height + 10;
        
        text = @"th";
        font = [UIFont fontWithName:@"Georgia" size:18];
        size = [text sizeWithFont:font];
        UILabel *yearSupLabel = [[[UILabel alloc] initWithFrame:CGRectMake(x, 20, size.width, size.height)] autorelease];
        yearSupLabel.text = text;
        yearSupLabel.font = font;
        yearSupLabel.backgroundColor = [UIColor clearColor];
        
        font = [UIFont fontWithName:@"Georgia" size:16];
        UILabel *reunionLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, y, image.size.width, font.lineHeight)] autorelease];
        reunionLabel.text = @"Reunion";
        reunionLabel.font = font;
        reunionLabel.backgroundColor = [UIColor clearColor];
        reunionLabel.textAlignment = UITextAlignmentCenter;
        y += reunionLabel.frame.size.height + 5;
        
        font = [UIFont fontWithName:@"Georgia" size:13];
        UILabel *dateLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, y, image.size.width, font.lineHeight)] autorelease];
        dateLabel.text = [homeModule reunionDateString];
        dateLabel.font = font;
        dateLabel.backgroundColor = [UIColor clearColor];
        dateLabel.textAlignment = UITextAlignmentCenter;
        
        [imageView addSubview:yearLabel];
        [imageView addSubview:yearSupLabel];
        [imageView addSubview:reunionLabel];
        [imageView addSubview:dateLabel];
        
        return imageView;
    }
    
    return nil;
}

- (NSArray *)widgetViews {
    KGONavigationStyle navStyle = [KGO_SHARED_APP_DELEGATE() navigationStyle];
    if (navStyle != KGONavigationStylePortlet) {
        return nil;
    }
    
    if (!self.userDescription) {
        ReunionHomeModule *homeModule = (ReunionHomeModule *)[KGO_SHARED_APP_DELEGATE() moduleForTag:@"home"];
        self.userDescription = [homeModule reunionName];
    }
    
    NSMutableArray *widgets = [NSMutableArray array];
    UIView *currentUserWidget = [self currentUserWidget];
    if (currentUserWidget) {
        [widgets addObject:currentUserWidget];
    }
    UIView *ribbonWidget = [self ribbonWidget];
    if (ribbonWidget) {
        [widgets addObject:ribbonWidget];
    }
    return widgets;
}


@end
