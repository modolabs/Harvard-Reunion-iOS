#import "ScheduleTabletTableViewCell.h"
#import "UIKit+KGOAdditions.h"
#import <QuartzCore/QuartzCore.h>

@implementation ScheduleTabletTableViewCell

@synthesize isFirstInSection, tableView;

/*
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}
*/

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.layer.cornerRadius = 5;

    if (self.scheduleCellType == ScheduleCellSelected) {
        if (!_fakeCardBorder) {
            _fakeCardBorder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 500)];
            _fakeCardBorder.tag = 3;
            _fakeCardBorder.layer.cornerRadius = 5;
            _fakeCardBorder.backgroundColor = [UIColor whiteColor];
            _fakeCardBorder.layer.shadowColor = [[UIColor blackColor] CGColor];
            _fakeCardBorder.layer.shadowOpacity = 0.5;
            _fakeCardBorder.layer.shadowOffset = CGSizeMake(1.0, 1.0);
            _fakeCardBorder.layer.borderWidth = 1;
            _fakeCardBorder.layer.borderColor = [[UIColor blackColor] CGColor];
            [self.contentView insertSubview:_fakeCardBorder atIndex:0];
        }
        
        _fakeTopOfNextCell.hidden = YES;
        
    } else {
        self.backgroundColor = [UIColor colorWithHexString:@"DBD9D8"];
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.detailTextLabel.backgroundColor = [UIColor clearColor];

        if (_fakeCardBorder) {
            [_fakeCardBorder removeFromSuperview];
            [_fakeCardBorder release];
            _fakeCardBorder = nil;
        }
        _fakeTopOfNextCell.hidden = NO;
    }
    
    if (self.scheduleCellType == ScheduleCellLastInTable || self.scheduleCellType == ScheduleCellSelected) {
        CGFloat gap = self.detailTextLabel.frame.origin.y - self.textLabel.frame.origin.y;
        
        CGRect frame = self.textLabel.frame;
        frame.origin.y = 10;
        self.textLabel.frame = frame;
        
        frame = self.detailTextLabel.frame;
        frame.origin.y = self.textLabel.frame.origin.y + gap;
        self.detailTextLabel.frame = frame;
    }
    
    UIImage *image = nil;
    if (self.scheduleCellType == ScheduleCellLastInSection || self.scheduleCellType == ScheduleCellTypeOther) {
        if (self.scheduleCellType == ScheduleCellLastInSection) {
            
            image = [UIImage imageWithPathName:@"modules/schedule/faketop-section"];
        } else {
            image = [UIImage imageWithPathName:@"modules/schedule/faketop-cell"];
        }
        
    } else if (self.scheduleCellType == ScheduleCellAboveSelectedRow) {
        image = [UIImage imageWithPathName:@"modules/schedule/faketop-above-selection"];
        //self.layer.shadowOpacity = 0;
        DLog(@"hid fake top of next cell for %@", self.textLabel.text);
    }

    if (image && !_fakeTopOfNextCell) {
        _fakeTopOfNextCell = [[UIImageView alloc] initWithImage:[image stretchableImageWithLeftCapWidth:5 topCapHeight:0]];
        _fakeTopOfNextCell.frame = CGRectMake(0, self.frame.size.height - 5, self.frame.size.width, 10);
        [self.contentView insertSubview:_fakeTopOfNextCell atIndex:0];
    } else if (image) {
        _fakeTopOfNextCell.image = [image stretchableImageWithLeftCapWidth:5 topCapHeight:0];
    }
    
    DLog(@"%@ %@", self.textLabel.text, self);
}

- (ScheduleCellType)scheduleCellType
{
    return _scheduleCellType;
}

- (void)setScheduleCellType:(ScheduleCellType)scheduleCellType
{
    if (scheduleCellType != _scheduleCellType) {
        _scheduleCellType = scheduleCellType;
        
        [self setNeedsLayout];
    }
}

- (void)dealloc
{
    [_fakeCardBorder release];
    [_fakeTopOfNextCell release];
    [super dealloc];
}

@end
