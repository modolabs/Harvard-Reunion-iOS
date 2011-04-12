#import "KGOModule.h"

extern NSString * const FacebookStatusDidUpdateNotification;
extern NSString * const TwitterStatusDidUpdateNotification;

@class KGOHomeScreenWidget;
@class MITThumbnailView;

#define CHAT_BUBBLE_TAG 35892

@interface MicroblogModule : KGOModule {
    
    KGOHomeScreenWidget *_chatBubble;
    KGOHomeScreenWidget *_buttonWidget;
    
    UILabel *_chatBubbleTitleLabel;
    UILabel *_chatBubbleSubtitleLabel;
    MITThumbnailView *_chatBubbleThumbnail;
    
}

- (void)hideChatBubble:(NSNotification *)aNotification;
- (void)didLogin:(NSNotification *)aNotification;

@property(nonatomic, retain) UIImage *buttonImage;
@property(nonatomic, retain) NSString *labelText;

@property(nonatomic, readonly) KGOHomeScreenWidget *buttonWidget;

// chat bubble properties
@property(nonatomic, readonly) KGOHomeScreenWidget *chatBubble;
@property(nonatomic, readonly) UILabel *chatBubbleTitleLabel;
@property(nonatomic, readonly) UILabel *chatBubbleSubtitleLabel;
@property(nonatomic, readonly) MITThumbnailView *chatBubbleThumbnail;
@property(nonatomic) CGFloat chatBubbleCaratOffset;

@end
