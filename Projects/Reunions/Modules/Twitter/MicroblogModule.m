#import "MicroblogModule.h"
#import "KGOHomeScreenWidget.h"
#import "KGOTheme.h"
#import "UIKit+KGOAdditions.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "KGOHomeScreenViewController.h"
#import "KGORequestManager.h"
#import "MITThumbnailView.h"
#import "Foundation+KGOAdditions.h"
#import <QuartzCore/QuartzCore.h>

// dimensions
#define BUTTON_WIDTH_IPHONE 122
#define BUTTON_HEIGHT_IPHONE 46

#define BUTTON_WIDTH_IPAD 80
#define BUTTON_HEIGHT_IPAD 100

#define BOTTOM_SHADOW_HEIGHT 8
#define LEFT_SHADOW_WIDTH 5

#define BUBBLE_HEIGHT_SIDEBAR 160

// tags
#define BUTTON_WIDGET_LABEL_TAG 324

NSString * const FacebookStatusDidUpdateNotification = @"FacebookUpdate";
NSString * const TwitterStatusDidUpdateNotification = @"TwitterUpdate";

@implementation MicroblogModule

@synthesize buttonImage, chatBubbleCaratOffset;

- (void)didLogin:(NSNotification *)aNotification
{
}

- (id)initWithDictionary:(NSDictionary *)moduleDict
{
    self = [super initWithDictionary:moduleDict];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didLogin:)
                                                     name:KGODidLoginNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // releases _chatBubbleTitleLabel, _chatBubbleSubtitleLabel,
    // _chatBubbleThumbnail
    [_chatBubble release];
    [_buttonWidget release];
    [_labelText release];
    
    [super dealloc];
}

#pragma mark chat bubble widget

- (void)hideChatBubble:(NSNotification *)aNotification {
    self.chatBubble.hidden = YES;
}

- (UILabel *)chatBubbleTitleLabel {
    return _chatBubbleTitleLabel;
}

- (UILabel *)chatBubbleSubtitleLabel {
    return _chatBubbleSubtitleLabel;
}

- (MITThumbnailView *)chatBubbleThumbnail
{
    return  _chatBubbleThumbnail;
}

- (KGOHomeScreenWidget *)chatBubble
{
    if (!_chatBubble) {
        
        _chatBubble = [[KGOHomeScreenWidget alloc] initWithFrame:CGRectZero];
        _chatBubble.module = self;
        _chatBubble.overlaps = YES;
        _chatBubble.tag = CHAT_BUBBLE_TAG;
        
        UIImage *bubbleImage = [UIImage imageWithPathName:@"common/chatbubble-body"];
        bubbleImage = [bubbleImage stretchableImageWithLeftCapWidth:10 topCapHeight:10];
        UIImageView *bubbleView = [[[UIImageView alloc] initWithImage:bubbleImage] autorelease];
        
        UIImage *caratImage = [UIImage imageWithPathName:@"common/chatbubble-carat"];
        UIImageView *caratView = [[[UIImageView alloc] initWithImage:caratImage] autorelease];

        NSInteger numberOfLinesForSubtitle = 1;
        CGRect frame = bubbleView.frame;

        KGOAppDelegate *appDelegate = KGO_SHARED_APP_DELEGATE();
        KGONavigationStyle navStyle = [appDelegate navigationStyle];
        BOOL isTablet = (navStyle == KGONavigationStyleTabletSidebar);
        
        KGOHomeScreenViewController *homeVC = (KGOHomeScreenViewController *)[appDelegate homescreen];
        CGRect bounds = homeVC.springboardFrame;
        
        if (isTablet) {
            numberOfLinesForSubtitle = 2;
            frame = CGRectMake(5, bounds.size.height - BUBBLE_HEIGHT_SIDEBAR - BUTTON_HEIGHT_IPAD, 150, BUBBLE_HEIGHT_SIDEBAR);
            bubbleView.frame = CGRectMake(0, 0, frame.size.width, frame.size.height - caratView.frame.size.height);
            CGFloat x = floor(self.chatBubbleCaratOffset * bubbleView.frame.size.width - caratView.frame.size.width / 2 + LEFT_SHADOW_WIDTH);
            caratView.frame = CGRectMake(x, bubbleView.frame.size.height - BOTTOM_SHADOW_HEIGHT,
                                         caratView.frame.size.width,
                                         caratView.frame.size.height);
        } else {
            _chatBubble.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
            CGFloat x = BUTTON_WIDTH_IPHONE + 5 - caratView.frame.size.width;
            frame = CGRectMake(x, bounds.size.height - frame.size.height,
                               bounds.size.width - x,
                               bubbleView.frame.size.height);
            
            bubbleView.frame = CGRectMake(caratView.frame.size.width - LEFT_SHADOW_WIDTH,
                                          0,
                                          frame.size.width - caratView.frame.size.width,
                                          frame.size.height);

            CGFloat y = floor(self.chatBubbleCaratOffset * bubbleView.frame.size.height - caratView.frame.size.height / 2);
            caratView.frame = CGRectMake(0, y,
                                         caratView.frame.size.width,
                                         caratView.frame.size.height);
        }
        _chatBubble.frame = frame;
        [_chatBubble addSubview:bubbleView];
        [_chatBubble addSubview:caratView];
        
        CGFloat bubbleHPadding = 10;
        CGFloat bubbleVPadding = isTablet ? 8 : 6;
        frame = CGRectMake(bubbleHPadding + bubbleView.frame.origin.x,
                           bubbleVPadding,
                           bubbleView.frame.size.width - bubbleHPadding * 2,
                           floor(bubbleView.frame.size.height * (isTablet ? 0.5 : 0.6)) - bubbleVPadding);

        _chatBubbleTitleLabel = [[[UILabel alloc] initWithFrame:frame] autorelease];
        _chatBubbleTitleLabel.numberOfLines = 0;
        _chatBubbleTitleLabel.text = NSLocalizedString(@"Loading...", nil);
        _chatBubbleTitleLabel.font = [UIFont systemFontOfSize:13];
        _chatBubbleTitleLabel.backgroundColor = [UIColor clearColor];
        [_chatBubble addSubview:_chatBubbleTitleLabel];

        frame.origin.y = frame.size.height + bubbleVPadding * 2;
        frame.size.height = bubbleView.frame.size.height - frame.origin.y - bubbleVPadding * 2;

        if (isTablet) {
            CGFloat oldWidth = frame.size.width;
            frame.size.width = frame.size.height;
            _chatBubbleThumbnail = [[[MITThumbnailView alloc] initWithFrame:frame] autorelease];
            [_chatBubble addSubview:_chatBubbleThumbnail];
            frame.origin.x += frame.size.width + 10;
            frame.size.width = oldWidth - frame.size.width - 10;
        }
        
        _chatBubbleSubtitleLabel = [[[UILabel alloc] initWithFrame:frame] autorelease];
        _chatBubbleSubtitleLabel.numberOfLines = numberOfLinesForSubtitle;
        _chatBubbleSubtitleLabel.font = [UIFont systemFontOfSize:12];
        _chatBubbleSubtitleLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1];
        _chatBubbleSubtitleLabel.backgroundColor = [UIColor clearColor];
        [_chatBubble addSubview:_chatBubbleSubtitleLabel];
        
        _chatBubble.hidden = YES;
    }
    
    
    KGOAppDelegate *appDelegate = KGO_SHARED_APP_DELEGATE();
    KGONavigationStyle navStyle = [appDelegate navigationStyle];
    KGOHomeScreenViewController *homeVC = (KGOHomeScreenViewController *)[appDelegate homescreen];
    CGRect frame = _chatBubble.frame;
    CGRect bounds = homeVC.springboardFrame;
    if (navStyle == KGONavigationStyleTabletSidebar) {
        frame.origin.y = bounds.size.height - BUBBLE_HEIGHT_SIDEBAR - BUTTON_HEIGHT_IPAD;
    } else {
        frame.origin.y = bounds.size.height - frame.size.height;
    }
    _chatBubble.frame = frame;
    
    return _chatBubble;
}

#pragma mark button widget

- (NSString *)labelText
{
    return _labelText;
}

- (void)setLabelText:(NSString *)labelText
{
    [_labelText release];
    _labelText = [labelText retain];
    if (_labelText) {
        UIButton *button = (UIButton *)[self.buttonWidget viewWithTag:BUTTON_WIDGET_LABEL_TAG];
        [button setTitle:_labelText forState:UIControlStateNormal];
    }
}

- (KGOHomeScreenWidget *)buttonWidget {
    if (!self.labelText) {
        return nil;
    }
    
    if (!_buttonWidget) {
        UIImage *backgroundImage = [UIImage imageWithPathName:@"modules/home/social-button"];
        CGRect frame = CGRectMake(0, 0, backgroundImage.size.width + 6, backgroundImage.size.height + 7);
        _buttonWidget = [[KGOHomeScreenWidget alloc] initWithFrame:frame];
        _buttonWidget.gravity = KGOLayoutGravityBottomLeft;
        _buttonWidget.behavesAsIcon = YES;
        _buttonWidget.module = self;
    }
    
    UIButton *button = (UIButton *)[_buttonWidget viewWithTag:BUTTON_WIDGET_LABEL_TAG];
    if (!button) {
        UIImage *backgroundImage = [UIImage imageWithPathName:@"modules/home/social-button"];
        UIImage *pressedBackground = [UIImage imageWithPathName:@"modules/home/social-button-pressed"];
        button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(4, 2, backgroundImage.size.width, backgroundImage.size.height);
        [button setBackgroundImage:backgroundImage forState:UIControlStateNormal];
        [button setBackgroundImage:pressedBackground forState:UIControlStateHighlighted];
        [button setImage:self.buttonImage forState:UIControlStateNormal];
        [button setTitle:self.labelText forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:12.5];
        button.titleLabel.numberOfLines = 2;
        button.titleLabel.lineBreakMode = UILineBreakModeWordWrap;
        button.titleLabel.layer.shadowColor = [[UIColor blackColor] CGColor];
        button.titleLabel.layer.shadowOffset = CGSizeMake(0, 1);
        button.titleLabel.layer.shadowOpacity = 0.5;
        button.titleLabel.layer.shadowRadius = 1;
        button.tag = BUTTON_WIDGET_LABEL_TAG;
        if (_buttonWidget.behavesAsIcon) {
            [button addTarget:_buttonWidget action:@selector(defaultTapAction:) forControlEvents:UIControlEventTouchUpInside];
        } else {
            [button addTarget:_buttonWidget action:@selector(customTapAction:) forControlEvents:UIControlEventTouchUpInside];
        }
        [_buttonWidget addSubview:button];
    }
    
    KGOAppDelegate *appDelegate = KGO_SHARED_APP_DELEGATE();
    KGONavigationStyle navStyle = [appDelegate navigationStyle];
    
    if (navStyle == KGONavigationStyleTabletSidebar) {
        CGFloat sidePadding = floor((button.frame.size.width - self.buttonImage.size.width) / 2);
        button.titleLabel.textAlignment = UITextAlignmentCenter;
        button.imageEdgeInsets = UIEdgeInsetsMake(0, sidePadding, self.buttonImage.size.height, sidePadding);
        button.titleEdgeInsets = UIEdgeInsetsMake(self.buttonImage.size.height + 10, -self.buttonImage.size.width, 0, 0);
        
    } else {
        CGSize maxSize = CGSizeMake(button.frame.size.width - self.buttonImage.size.width - 15, button.frame.size.height);
        CGSize textSize = [self.labelText sizeWithFont:button.titleLabel.font
                                     constrainedToSize:maxSize];
        
        CGFloat rightInset = maxSize.width - textSize.width + 5;
        button.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, rightInset);
        button.imageEdgeInsets = UIEdgeInsetsMake(3, 5, 3, rightInset + textSize.width);
    }
    
    return _buttonWidget;
}

- (NSArray *)widgetViews {
    NSDictionary *settings = [[NSUserDefaults standardUserDefaults] objectForKey:KGOUserPreferencesKey];
    if (!settings) {
        settings = [[KGO_SHARED_APP_DELEGATE() appConfig] objectForKey:@"DefaultUserSettings"];
    }
    NSArray *wantedWidgets = [settings arrayForKey:@"Widgets"];
    if (self.buttonWidget && [wantedWidgets containsObject:self.tag]) {
        return [NSArray arrayWithObjects:self.buttonWidget, self.chatBubble, nil];
    }
    return nil;
}

#pragma mark ipad animation

- (Class)feedViewControllerClass
{
    return [UIViewController class];
}

- (void)willShowModalFeedController
{
}

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params
{
    UIViewController *vc = nil;
    if ([KGO_SHARED_APP_DELEGATE() navigationStyle] != KGONavigationStyleTabletSidebar) {
        if ([pageName isEqualToString:LocalPathPageNameHome]) {
            vc = [[[[self feedViewControllerClass] alloc] initWithStyle:UITableViewStylePlain] autorelease];
            vc.title = [self feedViewControllerTitle];
        }
        
    } else {
        if (_modalFeedController) {
            return nil;
        }
        
        [self willShowModalFeedController];
        
        // circumvent the app delegate and present our own thing
        UIViewController *homescreen = [KGO_SHARED_APP_DELEGATE() homescreen];
        
        UIViewController *feedVC = [[[[self feedViewControllerClass] alloc] initWithStyle:UITableViewStylePlain] autorelease];
        _modalFeedController = [[UINavigationController alloc] initWithRootViewController:feedVC];
        
        feedVC.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                                 target:self
                                                                                                 action:@selector(hideModalFeedController:)] autorelease];
        
        CGRect frame = self.chatBubble.frame;
        frame.size.height -= 15;
        _modalFeedController.view.frame = frame;
        
        feedVC.view.layer.cornerRadius = 6;
        _modalFeedController.view.layer.cornerRadius = 6;
        
        CGRect screenFrame = [(KGOHomeScreenViewController *)homescreen springboardFrame];
        CGFloat bottom = frame.origin.y + frame.size.height;
        CGFloat top = 48;
        frame = CGRectMake(10, top, screenFrame.size.width - 20, bottom - top);
        
        _scrim = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenFrame.size.width, screenFrame.size.height)];
        _scrim.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        _scrim.alpha = 0;
        
        [homescreen.view addSubview:_scrim];
        [homescreen.view addSubview:_modalFeedController.view];
        
        // remove this temporarily to avoid animation artifacts
        UIBarButtonItem *item = feedVC.navigationItem.rightBarButtonItem;
        feedVC.navigationItem.rightBarButtonItem = nil;
        
        __block UIViewController *blockFeedVC = feedVC;
        [UIView animateWithDuration:0.4 animations:^(void) {
            _modalFeedController.view.frame = frame;
            _scrim.alpha = 1;
            
        } completion:^(BOOL finished) {
            blockFeedVC.navigationItem.rightBarButtonItem = item;
            blockFeedVC.navigationItem.title = [self feedViewControllerTitle];
        }];
    }
    return vc;
}

- (NSString *)feedViewControllerTitle
{
    return nil;
}

- (void)hideModalFeedController:(id)sender
{
    CGRect frame = self.chatBubble.frame;
    frame.size.height -= 15;
    
    [UIView animateWithDuration:0.4 animations:^(void) {
        _modalFeedController.view.frame = frame;
        _scrim.alpha = 0;
        
    } completion:^(BOOL finished) {
        [_scrim removeFromSuperview];
        [_scrim release];
        _scrim = nil;
        
        [_modalFeedController.view removeFromSuperview];
        [_modalFeedController release];
        _modalFeedController = nil;
    }];
}

@end
