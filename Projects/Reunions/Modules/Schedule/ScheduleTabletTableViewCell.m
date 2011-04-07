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
    //self.layer.shadowOffset = CGSizeMake(1.0, 0);
    //self.layer.shadowColor = [[UIColor blackColor] CGColor];
    //self.layer.shadowOpacity = 0.5;
    
    NSLog(@"%@ %@", self.textLabel.text, self);
    
    CGRect frame = self.frame;
    frame.size.width = self.tableView.frame.size.width - 8;

    if (self.scheduleCellType == ScheduleCellSelected) {
        self.backgroundColor = [UIColor clearColor];
        
        if (!_fakeCardBorder) {
            _fakeCardBorder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width - 8, 500)];
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
        
        frame.origin.x = 0;
        
        if (!_fakeBehindCardBorder) {
            _fakeBehindCardBorder = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width - 16, -10, 16, 440)];
            _fakeBehindCardBorder.layer.cornerRadius = 8;
            _fakeBehindCardBorder.tag = 4;
            _fakeBehindCardBorder.hidden = NO;
            [self.contentView insertSubview:_fakeBehindCardBorder atIndex:0];
        }

        if (self.isFirstInSection) {
            _fakeBehindCardBorder.backgroundColor = [UIColor colorWithHexString:@"030100"];
        } else {
            _fakeBehindCardBorder.backgroundColor = [UIColor colorWithHexString:@"DBD9D8"];
        }

        /*
        if (!self.isFirstInSection) {
            
        } else {
            if (_fakeBehindCardBorder) {
                [_fakeBehindCardBorder removeFromSuperview];
                [_fakeBehindCardBorder release];
                _fakeBehindCardBorder = nil;
            }
        }
        */
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
        if (_fakeBehindCardBorder) {
            [_fakeBehindCardBorder removeFromSuperview];
            [_fakeBehindCardBorder release];
            _fakeBehindCardBorder = nil;
        }
        
        _fakeTopOfNextCell.hidden = NO;
        
        frame.origin.x = 8;
    }

    NSLog(@"%@ %@", self.textLabel.text, _fakeBehindCardBorder);
    
    self.frame = frame;
    
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
        NSLog(@"hid fake top of next cell for %@", self.textLabel.text);
    }

    if (image && !_fakeTopOfNextCell) {
        _fakeTopOfNextCell = [[UIImageView alloc] initWithImage:[image stretchableImageWithLeftCapWidth:5 topCapHeight:0]];
        _fakeTopOfNextCell.frame = CGRectMake(0, self.frame.size.height - 5, self.frame.size.width, 10);
        [self.contentView insertSubview:_fakeTopOfNextCell atIndex:0];
    } else if (image) {
        _fakeTopOfNextCell.image = [image stretchableImageWithLeftCapWidth:5 topCapHeight:0];
    }
    
    NSLog(@"%@ %@", self.textLabel.text, self);
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
    [_fakeBehindCardBorder release];
    [super dealloc];
}

@end
