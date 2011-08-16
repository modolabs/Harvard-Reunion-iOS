
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

//
//  FacebookThumbnail.h
//  

#import <Foundation/Foundation.h>
#import "MITThumbnailView.h"

@class FacebookPhoto;

@protocol FacebookThumbSource

- (NSString *)title;
- (NSData *)thumbData;
- (void)setThumbData:(NSData *)data;
- (NSString *)thumbnailSourceURLString;

@optional

- (NSData *)mediaData;

@end


@interface FacebookThumbnail : UIControl <MITThumbnailDelegate> {
    UILabel *_label;
    MITThumbnailView *_thumbnail;
    CGFloat _rotationAngle;
    NSObject<FacebookThumbSource> *thumbSource;
}

@property (nonatomic) CGFloat rotationAngle;
@property (nonatomic, retain) NSObject<FacebookThumbSource> *thumbSource;
@property (nonatomic, retain) MITThumbnailView *thumbnailView;
@property (assign) BOOL shouldDisplayLabels;

- (id)initWithFrame:(CGRect)frame displayLabels:(BOOL)displayLabels;
- (void)highlightIntoFrame:(CGRect)frame;
- (void)hide;

@end

