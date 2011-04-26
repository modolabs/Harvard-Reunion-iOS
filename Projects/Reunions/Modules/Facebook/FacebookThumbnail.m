//
//  FacebookThumbnail.m
//

#import "FacebookThumbnail.h"
#import <QuartzCore/QuartzCore.h>
#import "KGOTheme.h"
#import "Foundation+KGOAdditions.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "FacebookModel.h"
#import "CoreDataManager.h"

@implementation FacebookThumbnail

@synthesize thumbSource;
@synthesize thumbnailView = _thumbnail;
@synthesize shouldDisplayLabels;

static const CGFloat kThumbnailLabelHeight = 40.0f;

- (id)initWithFrame:(CGRect)frame displayLabels:(BOOL)displayLabels {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.shouldDisplayLabels = displayLabels;
        
        if (self.shouldDisplayLabels) {
            CGRect labelFrame = 
            CGRectMake(0, 
                       frame.size.height - kThumbnailLabelHeight, 
                       frame.size.width, 
                       kThumbnailLabelHeight);
            _label = [[UILabel alloc] initWithFrame:labelFrame];
            _label.backgroundColor = [UIColor clearColor];
            _label.textColor = [UIColor whiteColor];
            _label.numberOfLines = 3;
            _label.font = [[KGOTheme sharedTheme] 
                           fontForThemedProperty:KGOThemePropertySmallPrint];
            _label.userInteractionEnabled = NO;
        }

        CGFloat thumbnailViewHeight = frame.size.height;
        if (self.shouldDisplayLabels) {
            thumbnailViewHeight -= kThumbnailLabelHeight;
        }
        _thumbnail = 
        [[MITThumbnailView alloc] initWithFrame:
         CGRectMake(0, 0, frame.size.width, thumbnailViewHeight)];
        _thumbnail.contentMode = UIViewContentModeScaleAspectFit;
        _thumbnail.userInteractionEnabled = NO;
        _thumbnail.delegate = self;
        
        // add drop shadow
        _thumbnail.layer.shadowOffset = CGSizeMake(0, 1);
        _thumbnail.layer.shadowColor = [[UIColor blackColor] CGColor];
        _thumbnail.layer.shadowRadius = 4.0;
        _thumbnail.layer.shadowOpacity = 0.8;
        
        // this prevents choppy looking edges 
        // when photo is rotated
        _thumbnail.layer.shouldRasterize = YES;
        
        [self addSubview:_thumbnail];
        if (self.shouldDisplayLabels) {
            [self addSubview:_label];
        }
    }
    return self;
}

- (NSObject<FacebookThumbSource> *)thumbSource {
    return thumbSource;
}

- (void)setThumbSource:(NSObject<FacebookThumbSource> *)aThumbSource {
    [thumbSource release];
    thumbSource = [aThumbSource retain];
    
    if (self.shouldDisplayLabels) {
        _label.text = [thumbSource title];
    }
    if ([thumbSource thumbData]) {
        _thumbnail.imageData = [thumbSource thumbData];
        [_thumbnail displayImage];
    } else if ([thumbSource respondsToSelector:@selector(mediaData)] && 
               [thumbSource mediaData]) {
        _thumbnail.imageData = [thumbSource mediaData];
        [_thumbnail displayImage];
    } else if ([thumbSource thumbnailSourceURLString]) {
        _thumbnail.imageURL = [thumbSource thumbnailSourceURLString];
        [_thumbnail loadImage];
    }
}

- (void)thumbnail:(MITThumbnailView *)thumbnail didLoadData:(NSData *)data {
    [self.thumbSource setThumbData:data];
    [[CoreDataManager sharedManager] saveData];
}

- (CGFloat)rotationAngle {
    return _rotationAngle;
}

- (void)setRotationAngle:(CGFloat)rotationAngle {
    _rotationAngle = rotationAngle;
    _thumbnail.transform = CGAffineTransformMakeRotation(rotationAngle);
}

- (void)highlightIntoFrame:(CGRect)frame {
    // frame given relative the super view
    CGRect thumbnailFrame = CGRectMake(
                                       frame.origin.x - self.frame.origin.x, 
                                       frame.origin.y - self.frame.origin.y,
                                       frame.size.width,
                                       frame.size.height);
    
    _thumbnail.transform = CGAffineTransformMakeRotation(0);
    _thumbnail.frame = thumbnailFrame;
    _label.alpha = 0.0;
}

- (void)hide {
    _thumbnail.alpha = 0.0;
    _label.alpha = 0.0;
}

- (void)dealloc {
    [thumbSource release];
    _thumbnail.delegate = nil;
    [_thumbnail release];
    [_label release];
    [super dealloc];
}

@end
