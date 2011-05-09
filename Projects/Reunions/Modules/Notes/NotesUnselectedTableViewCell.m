#import "NotesUnselectedTableViewCell.h"
#import "UIKit+KGOAdditions.h"
#import <QuartzCore/QuartzCore.h>
#import "KGOTheme.h"

@implementation NotesUnselectedTableViewCell
@synthesize tableView;
@synthesize notesCellType;
@synthesize detailsView;



- (void)dealloc
{
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
        
        frame.origin.x = 8;
        //frame.size.height += 10;
        
        self.frame = frame;
        
        //UIImage *image = nil;
        //image = [UIImage imageWithPathName:@"common/bar-drop-shadow"];

    } else if (notesCellType == NotesCellSelected) {
        self.frame = frame;
        
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
}

@end
