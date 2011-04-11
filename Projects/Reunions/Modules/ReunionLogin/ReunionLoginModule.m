#import "ReunionLoginModule.h"
#import "KGOHomeScreenWidget.h"
#import "KGOHomeScreenViewController.h"
#import "KGOTheme.h"
#import "UIKit+KGOAdditions.h"
#import "ReunionHomeModule.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "Foundation+KGOAdditions.h"

@implementation ReunionLoginModule

- (UIView *)currentUserWidget
{
    NSDictionary *userDict = [[[KGORequestManager sharedManager] sessionInfo] dictionaryForKey:@"user"];
    
    self.username = [userDict stringForKey:@"name" nilIfEmpty:YES];
    
    KGOHomeScreenViewController *homeVC = (KGOHomeScreenViewController *)[KGO_SHARED_APP_DELEGATE() homescreen];
    CGRect frame = [homeVC springboardFrame];
    UIImage *image = [UIImage imageWithPathName:@"modules/home/ribbon"];
    frame = CGRectMake(10, 10, frame.size.width - image.size.width - 20, 90);
    KGOHomeScreenWidget *widget = [[[KGOHomeScreenWidget alloc] initWithFrame:frame] autorelease];
    
    NSString *title = self.username;
    NSString *subtitle = self.userDescription;
    if (!title) {
        title = self.userDescription;
        subtitle = nil;
    }
    
    UILabel *titleLabel = nil;
    
    CGFloat y = 10;
    
    if (subtitle) {
        UIFont *font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyBodyText];
        CGSize size = [self.userDescription sizeWithFont:font constrainedToSize:widget.frame.size];
        UILabel *subtitleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, y, size.width, size.height)] autorelease];
        subtitleLabel.font = font;
        subtitleLabel.backgroundColor = [UIColor clearColor];
        subtitleLabel.textColor = [UIColor whiteColor];
        subtitleLabel.text = subtitle;
        
        y += subtitleLabel.frame.size.height + 10;
        
        [widget addSubview:subtitleLabel];
    }
    
    if (title) {
        UIFont *font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyContentTitle];
        titleLabel = [UILabel multilineLabelWithText:title font:font width:widget.frame.size.width];
        titleLabel.textColor = [UIColor whiteColor];
        CGRect frame = titleLabel.frame;
        frame.origin.x = 10;
        frame.origin.y = y;
        titleLabel.frame = frame;
        
        [widget addSubview:titleLabel];
    }
    
    widget.behavesAsIcon = NO;
    
    return widget;
}

- (KGOHomeScreenWidget *)ribbonWidget
{
    KGOAppDelegate *appDelegate = KGO_SHARED_APP_DELEGATE();
    
    ReunionHomeModule *homeModule = (ReunionHomeModule *)[appDelegate moduleForTag:@"home"];
    
    KGONavigationStyle navStyle = [appDelegate navigationStyle];
    if (navStyle == KGONavigationStylePortlet) {
        UIImage *image = [UIImage imageWithPathName:@"modules/home/ribbon"];
        UIImageView *imageView = [[[UIImageView alloc] initWithImage:image] autorelease];
    
        // reunion number
        NSString *text = [homeModule reunionNumber];
        UIFont *font = [UIFont fontWithName:@"Georgia" size:38];
        CGSize size = CGSizeZero;
        if (text) {
            size = [text sizeWithFont:font];
        }

        UILabel *yearLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)] autorelease];
        yearLabel.text = text;
        yearLabel.font = font;
        yearLabel.textColor = [UIColor whiteColor];
        yearLabel.backgroundColor = [UIColor clearColor];
        CGFloat y = size.height;

        // reunion number superscript
        text = @"th";
        font = [UIFont fontWithName:@"Georgia" size:18];
        size = [text sizeWithFont:font];
        UILabel *yearSupLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 5, size.width, size.height)] autorelease];
        yearSupLabel.text = text;
        yearSupLabel.font = font;
        yearSupLabel.textColor = [UIColor whiteColor];
        yearSupLabel.backgroundColor = [UIColor clearColor];

        // position above two elements
        CGFloat x = floor((imageView.frame.size.width - yearLabel.frame.size.width - yearSupLabel.frame.size.width) / 2);
        CGRect yearFrame = yearLabel.frame;
        yearFrame.origin.x = x;
        yearLabel.frame = yearFrame;
        yearFrame = yearSupLabel.frame;
        yearFrame.origin.x = x + yearLabel.frame.size.width;
        yearSupLabel.frame = yearFrame;
        
        // "reunion"
        font = [UIFont fontWithName:@"Georgia" size:16];
        UILabel *reunionLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, y, image.size.width, font.lineHeight)] autorelease];
        reunionLabel.text = @"Reunion";
        reunionLabel.font = font;
        reunionLabel.backgroundColor = [UIColor clearColor];
        reunionLabel.textAlignment = UITextAlignmentCenter;
        reunionLabel.textColor = [UIColor whiteColor];
        y += reunionLabel.frame.size.height;

        // reunion date
        font = [UIFont fontWithName:@"Georgia" size:13];
        UILabel *dateLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, y, image.size.width, font.lineHeight)] autorelease];
        dateLabel.text = [homeModule reunionDateString];
        dateLabel.font = font;
        dateLabel.backgroundColor = [UIColor clearColor];
        dateLabel.textColor = [UIColor whiteColor];
        dateLabel.textAlignment = UITextAlignmentCenter;
        
        CGRect frame = imageView.frame;
        CGRect springboardFrame = [(KGOHomeScreenViewController *)[appDelegate homescreen] springboardFrame];
        frame.origin.x = springboardFrame.size.width - frame.size.width - 10;
        KGOHomeScreenWidget *widget = [[[KGOHomeScreenWidget alloc] initWithFrame:frame] autorelease];
        
        [widget addSubview:imageView];
        [widget addSubview:yearLabel];
        [widget addSubview:yearSupLabel];
        [widget addSubview:reunionLabel];
        [widget addSubview:dateLabel];
        
        widget.behavesAsIcon = NO;
        widget.overlaps = YES;
        
        return widget;
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
