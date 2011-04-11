//
//  MediaImageView.h
//  Reunions
//
//  Created by Brian Patt on 4/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MediaContainerView : UIView {
    
}

@property (nonatomic, retain) UIImageView *imageView;

- (void)setImage:(UIImage *)image;
+ (CGFloat)heightForImageSize:(CGSize)size fitToWidth:(CGFloat)width;

@end
