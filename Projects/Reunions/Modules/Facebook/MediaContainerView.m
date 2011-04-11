#import "MediaContainerView.h"
#define MAXIMUM_IMAGE_HEIGHT 500

@interface MediaContainerView (Private) 

+ (CGFloat)deltaHeightForImageSize:(CGSize)size fitToWidth:(CGFloat)width oldHeight:(CGFloat)oldHeight;
- (void)setFrame:(CGRect)frame withImageHeight:(CGFloat)height;

@end

@implementation MediaContainerView
@synthesize imageView;

+ (CGFloat)heightForImageSize:(CGSize)size fitToWidth:(CGFloat)width {
    CGFloat newHeight = size.height *  (width / size.width);
    if (newHeight > MAXIMUM_IMAGE_HEIGHT) {
        newHeight = MAXIMUM_IMAGE_HEIGHT;
    }
    return  newHeight;
}

- (void)setImage:(UIImage *)image {
    self.imageView.image = image;
    
    CGFloat newHeight;
    if (image) {
        newHeight = [MediaContainerView heightForImageSize:image.size 
                                                   fitToWidth:self.imageView.frame.size.width];
    } else {
        newHeight = 0;
    }
    
    [self setFrame:self.frame withImageHeight:newHeight];
}

- (void)setFrame:(CGRect)frame withImageHeight:(CGFloat)height {
    CGFloat deltaHeight = height - self.imageView.frame.size.height;
    frame.size.height = frame.size.height + deltaHeight;
    [super setFrame:frame];
}

- (void)setFrame:(CGRect)frame {
    if(self.imageView.image) {
        CGFloat deltaWidth = frame.size.width - self.frame.size.width;
        CGFloat newWidth = self.imageView.frame.size.width + deltaWidth;
        CGFloat newHeight = [MediaContainerView heightForImageSize:self.imageView.image.size fitToWidth:newWidth];
        [self setFrame:frame withImageHeight:newHeight];
    } else {
        [super setFrame:frame];
    }
}

@end
