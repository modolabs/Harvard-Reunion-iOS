//
//  NotesUnselectedTableViewCell.m
//  Reunions
//
//  Created by Muhammad J Amjad on 4/15/11.
//  Copyright 2011 ModoLabs Inc. All rights reserved.
//

#import "NotesUnselectedTableViewCell.h"
#import "UIKit+KGOAdditions.h"
#import <QuartzCore/QuartzCore.h>

@implementation NotesUnselectedTableViewCell
@synthesize tableView;
@synthesize notesCellType;
@synthesize detailsView;



- (void)dealloc
{
    [_fakeCardBorder release];
    [_fakeTopOfNextCell release];
    [_fakeBehindCardBorder release];
    [super dealloc];
}


- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGFloat locations[2] = { 0.0, 1.0 };
    
    unsigned int r1, g1, b1, r2, g2, b2; // 1: start color; 2: end color
    // breaking down hex colors from #eee4b8, #e8d9a3
    // TODO: cache the gradient object somewhere so we don't have to keep recreating it
    [[NSScanner scannerWithString:@"ee"] scanHexInt:&r1];
    [[NSScanner scannerWithString:@"e4"] scanHexInt:&g1];
    [[NSScanner scannerWithString:@"b8"] scanHexInt:&b1];
    [[NSScanner scannerWithString:@"e8"] scanHexInt:&r2];
    [[NSScanner scannerWithString:@"d9"] scanHexInt:&g2];
    [[NSScanner scannerWithString:@"a3"] scanHexInt:&b2];
    
    CGFloat components[8] = {
        (float)r1/255.0f,
        (float)g1/255.0f,
        (float)b1/255.0f,
        1.0,
        (float)r2/255.0f,
        (float)g2/255.0f,
        (float)b2/255.0f,
        1.0 };
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, components, locations, 2);
    
    CGPoint startPoint = CGPointMake(CGRectGetMidX(rect), 0);
    CGPoint endPoint = CGPointMake(CGRectGetMidX(rect), rect.size.height);
    
    CGContextDrawLinearGradient(currentContext, gradient, startPoint, endPoint, 0);
    CGColorSpaceRelease(colorSpace);
    CGGradientRelease(gradient);
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    
    NSLog(@"%@ %@", self.textLabel.text, self);
    
    CGRect frame = self.frame;
    frame.size.width = self.tableView.frame.size.width - 8;
    
    
    if (notesCellType == NotesCellTypeOther){
        //self.backgroundColor = [UIColor colorWithHexString:@"DBD9D8"];
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.numberOfLines = 1;
        self.textLabel.lineBreakMode = UILineBreakModeTailTruncation;
        
        CGRect detailedLabelFrame = self.detailTextLabel.frame;
        self.detailTextLabel.frame = CGRectMake(detailedLabelFrame.origin.x, detailedLabelFrame.origin.y + 2, 
                                                detailedLabelFrame.size.width, detailedLabelFrame.size.height);
        self.detailTextLabel.backgroundColor = [UIColor clearColor];
        self.detailTextLabel.numberOfLines = 1;
        self.detailTextLabel.lineBreakMode = UILineBreakModeTailTruncation;
        
        if (_fakeCardBorder) {
            [_fakeCardBorder removeFromSuperview];
            [_fakeCardBorder release];
            _fakeCardBorder = nil;
        }
        if (_fakeBehindCardBorder) {
            [_fakeBehindCardBorder removeFromSuperview];
            [_fakeBehindCardBorder release];
            _fakeBehindCardBorder = nil;
        }
        
        _fakeTopOfNextCell.hidden = NO;
        
        frame.origin.x = 8;
        //frame.size.height += 10;
        
        NSLog(@"%@ %@", self.textLabel.text, _fakeBehindCardBorder);
        
        self.frame = frame;
        
        UIImage *image = nil;
        image = [UIImage imageWithPathName:@"common/bar-drop-shadow"];
        
        if (image && !_fakeTopOfNextCell) {
            _fakeTopOfNextCell = [[UIImageView alloc] initWithImage:[image stretchableImageWithLeftCapWidth:0 topCapHeight:0]];
            _fakeTopOfNextCell.frame = CGRectMake(-7, self.frame.size.height - 5, self.frame.size.width, 5);
            [self.contentView insertSubview:_fakeTopOfNextCell atIndex:0];
        } else if (image) {
            _fakeTopOfNextCell.image = [image stretchableImageWithLeftCapWidth:0 topCapHeight:0];
        }
    }
    else if (notesCellType == NotesCellSelected) {
        NSLog(@"%@ %@", self.textLabel.text, _fakeBehindCardBorder);
        
        self.frame = frame;
        
        //UIImage *image = nil;
        
        for (UIView * aView in self.subviews){
            
            if ([aView isKindOfClass:[NotesTextView class]]){
                [aView removeFromSuperview];
            }
        }
        
        if (nil != detailsView) {
            //frame = detailsView.frame;
            [self addSubview:detailsView];

        }
    }
    

    /*if (self.scheduleCellType == ScheduleCellLastInSection || self.scheduleCellType == ScheduleCellTypeOther) {
        if (self.scheduleCellType == ScheduleCellLastInSection) {
            image = [UIImage imageWithPathName:@"modules/schedule/faketop-section"];
        } else {
            image = [UIImage imageWithPathName:@"modules/schedule/faketop-cell"];
        }
        
    } else if (self.scheduleCellType == ScheduleCellAboveSelectedRow) {
        image = [UIImage imageWithPathName:@"modules/schedule/faketop-above-selection"];
        //self.layer.shadowOpacity = 0;
        NSLog(@"hid fake top of next cell for %@", self.textLabel.text);
    }*/
    

    
    NSLog(@"%@ %@", self.textLabel.text, self);
}

@end
