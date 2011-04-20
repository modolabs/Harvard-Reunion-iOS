#import "ReunionLoginModule.h"
#import "KGOHomeScreenWidget.h"
#import "KGOHomeScreenViewController.h"
#import "KGOTheme.h"
#import "UIKit+KGOAdditions.h"
#import "ReunionHomeModule.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "Foundation+KGOAdditions.h"

#define IPAD_CURRENTUSER_FONT 20

@implementation ReunionLoginModule

- (UIView *)currentUserWidget
{
    NSDictionary *userDict = [[[KGORequestManager sharedManager] sessionInfo] dictionaryForKey:@"user"];
    
    self.username = [userDict stringForKey:@"name" nilIfEmpty:YES];
    
    KGOAppDelegate *appDelegate = KGO_SHARED_APP_DELEGATE();
    KGONavigationStyle navStyle = [appDelegate navigationStyle];
    CGRect frame = CGRectZero;
    if (navStyle == KGONavigationStylePortlet) {
        KGOHomeScreenViewController *homeVC = (KGOHomeScreenViewController *)[appDelegate homescreen];
        frame = [homeVC springboardFrame];
        UIImage *image = [UIImage imageWithPathName:@"modules/home/ribbon"];
        frame = CGRectMake(10, 10, frame.size.width - image.size.width - 30, 90);
    } else {
        frame = CGRectZero;
    }
    KGOHomeScreenWidget *widget = [[[KGOHomeScreenWidget alloc] initWithFrame:frame] autorelease];
    
    NSString *title = self.username;
    NSString *subtitle = self.userDescription;
    if (!title) {
        title = self.userDescription;
        subtitle = nil;
    }
    
    UILabel *titleLabel = nil;
    UILabel *subtitleLabel = nil;
    
    CGFloat y = 10; // iphone only
    
    if (subtitle) {
        UIFont *font;
        CGRect frame;
        if (navStyle == KGONavigationStylePortlet) {
            font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyBodyText];
            CGSize size = [subtitle sizeWithFont:font constrainedToSize:widget.frame.size];
            frame = CGRectMake(10, y, size.width, size.height);
        } else {
            subtitle = [NSString stringWithFormat:@"%@ : ", subtitle];
            font = [UIFont boldSystemFontOfSize:IPAD_CURRENTUSER_FONT];
            CGSize size = [subtitle sizeWithFont:font];
            frame = CGRectMake(0, 0, size.width, size.height);
        }
        
        subtitleLabel = [[[UILabel alloc] initWithFrame:frame] autorelease];
        subtitleLabel.font = font;
        subtitleLabel.backgroundColor = [UIColor clearColor];
        subtitleLabel.textColor = [UIColor whiteColor];
        subtitleLabel.text = subtitle;
        
        y += subtitleLabel.frame.size.height + 10;
        
        [widget addSubview:subtitleLabel];
    }
    
    if (title) {
        if (navStyle == KGONavigationStylePortlet) {
            UIFont *font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyContentTitle];
            titleLabel = [UILabel multilineLabelWithText:title font:font width:widget.frame.size.width];
            CGRect frame = titleLabel.frame;
            frame.origin.x = 10;
            frame.origin.y = y;
            titleLabel.frame = frame;
            titleLabel.textColor = [UIColor whiteColor];
            
        } else {
            UIFont *font = [UIFont boldSystemFontOfSize:IPAD_CURRENTUSER_FONT];
            CGSize size = [title sizeWithFont:font];
            CGRect frame = CGRectMake(0, 0, size.width, size.height);
            titleLabel = [[[UILabel alloc] initWithFrame:frame] autorelease];
            titleLabel.text = title;
            titleLabel.backgroundColor = [UIColor clearColor];
            titleLabel.font = font;
            titleLabel.textColor = [UIColor whiteColor];
            
            CGFloat width = titleLabel.frame.size.width;
            if (subtitleLabel) {
                width += subtitleLabel.frame.size.width;
                CGRect titleFrame = titleLabel.frame;
                titleFrame.origin.x += subtitleLabel.frame.size.width;
                titleLabel.frame = titleFrame;
            }
        }
        
        [widget addSubview:titleLabel];
    }
    
    if (navStyle == KGONavigationStyleTabletSidebar) {
        CGRect outerFrame = [(KGOHomeScreenViewController *)[appDelegate homescreen] springboardFrame];
        
        frame = widget.frame;
        CGFloat titleWidth = (titleLabel != nil) ? titleLabel.frame.size.width : 0;
        CGFloat subtitleWidth = (subtitleLabel != nil) ? subtitleLabel.frame.size.width : 0;
        CGFloat titleHeight = (titleLabel != nil) ? titleLabel.frame.size.height : 0;
        CGFloat subtitleHeight = (subtitleLabel != nil) ? subtitleLabel.frame.size.height : 0;
        
        frame.size.width = titleWidth + subtitleWidth;
        frame.size.height = fmaxf(titleHeight, subtitleHeight);
        frame.origin.y = 10;
        frame.origin.x = floorf((outerFrame.size.width - frame.size.width) / 2);
        
        widget.frame = frame;
        widget.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        widget.overlaps = YES;
    }
    
    widget.behavesAsIcon = NO;
    
    return widget;
}

- (KGOHomeScreenWidget *)ribbonWidget
{
    KGOAppDelegate *appDelegate = KGO_SHARED_APP_DELEGATE();
    
    ReunionHomeModule *homeModule = (ReunionHomeModule *)[appDelegate moduleForTag:@"home"];
    
    KGONavigationStyle navStyle = [appDelegate navigationStyle];
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
    if (navStyle == KGONavigationStylePortlet) {
        frame.origin.x = springboardFrame.size.width - frame.size.width - 10;
    } else {
        frame.origin.x = 36;
    }
    KGOHomeScreenWidget *widget = [[[KGOHomeScreenWidget alloc] initWithFrame:frame] autorelease];
    
    [widget addSubview:imageView];
    [widget addSubview:yearLabel];
    [widget addSubview:yearSupLabel];
    [widget addSubview:reunionLabel];
    [widget addSubview:dateLabel];
    
    widget.behavesAsIcon = NO;
    
    if (navStyle == KGONavigationStylePortlet) {
        widget.overlaps = YES;
    } else {
        widget.gravity = KGOLayoutGravityTopLeft;
    }
    
    return widget;
}

- (NSArray *)widgetViews {
    
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

- (BOOL)webViewController:(KGOWebViewController *)webVC shouldLoadExternallyForURL:(NSURL *)url
{
    return [[url absoluteString] rangeOfString:[[KGORequestManager sharedManager] host]].location == NSNotFound;
}


@end
