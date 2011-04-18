#import "ScheduleTabletTableViewCell.h"
#import "UIKit+KGOAdditions.h"
#import "ScheduleDetailTableView.h"
#import "ScheduleEventWrapper.h"
#import <QuartzCore/QuartzCore.h>

#define TABLE_TAG 1

@implementation ScheduleTabletTableViewCell

@synthesize isFirstInSection, tableView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        CGRect frame = CGRectMake(self.frame.size.width - 60, -2, 30, 40);
        _bookmarkView = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        _bookmarkView.frame = frame;
        _bookmarkView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [self.contentView addSubview:_bookmarkView];
        
    }
    return self;
}

- (void)addBookmark:(id)sender
{
    ScheduleDetailTableView *detailTV = (ScheduleDetailTableView *)[self.contentView viewWithTag:TABLE_TAG];
    if (detailTV) {
        [detailTV.event addBookmark];
        [_bookmarkView setImage:[UIImage imageWithPathName:@"common/bookmark-ribbon-on"] forState:UIControlStateNormal];
    }
}

- (void)removeBookmark:(id)sender
{
    ScheduleDetailTableView *detailTV = (ScheduleDetailTableView *)[self.contentView viewWithTag:TABLE_TAG];
    if (detailTV) {
        [detailTV.event removeBookmark];
        [_bookmarkView setImage:[UIImage imageWithPathName:@"common/bookmark-ribbon-off"] forState:UIControlStateNormal];
    }
}

- (void)refuseToRemoveBookmark:(id)sender
{
    UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:nil
                                                         message:@"Events you have registered for cannot be removed from your schedule."
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil] autorelease];
    [alertView show];
}

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
        
        ScheduleDetailTableView *detailTV = (ScheduleDetailTableView *)[self.contentView viewWithTag:TABLE_TAG];
        if (detailTV && [detailTV.event isKindOfClass:[ScheduleEventWrapper class]]) {
            if ([(ScheduleEventWrapper *)detailTV.event isRegistered]) {
                [_bookmarkView addTarget:self action:@selector(refuseToRemoveBookmark:) forControlEvents:UIControlEventTouchUpInside];
            } else if ([detailTV.event isBookmarked]) {
                [_bookmarkView addTarget:self action:@selector(removeBookmark:) forControlEvents:UIControlEventTouchUpInside];
            } else {
                [_bookmarkView addTarget:self action:@selector(addBookmark:) forControlEvents:UIControlEventTouchUpInside];
            }
        }
        
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
        
        [_bookmarkView removeTarget:NULL action:NULL forControlEvents:UIControlEventTouchUpInside];
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
        
    }

    if (image && !_fakeTopOfNextCell) {
        _fakeTopOfNextCell = [[UIImageView alloc] initWithImage:[image stretchableImageWithLeftCapWidth:5 topCapHeight:0]];
        _fakeTopOfNextCell.frame = CGRectMake(0, self.frame.size.height - 5, self.frame.size.width, 10);
        [self.contentView insertSubview:_fakeTopOfNextCell atIndex:0];
    } else if (image) {
        _fakeTopOfNextCell.image = [image stretchableImageWithLeftCapWidth:5 topCapHeight:0];
    }
}

- (UIButton *)bookmarkView
{
    return _bookmarkView;
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
    [_bookmarkView release];
    [super dealloc];
}

@end
