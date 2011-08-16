
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import <Foundation/Foundation.h>


@interface MediaContainerView : UIView {
    CGSize _previewSize;
    UIView *_previewView;
    
    CGFloat _maximumPreviewHeight;
    CGFloat _fixedPreviewHeight;
}

- (UIView *)previewView;

- (void)setPreviewSize:(CGSize)size;
- (void)initPreviewView:(UIView *)view;
- (void)setPreviewView:(UIView *)view;
+ (CGFloat)heightForImageSize:(CGSize)size fitToWidth:(CGFloat)width maxHeight:(CGFloat)maxHeight;
+ (CGFloat)defaultMaxHeight;

@property CGFloat maximumPreviewHeight;
@property CGFloat fixedPreviewHeight;

@end
