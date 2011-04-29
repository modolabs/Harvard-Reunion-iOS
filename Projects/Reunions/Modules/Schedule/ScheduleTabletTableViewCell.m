#import "ScheduleTabletTableViewCell.h"
#import "UIKit+KGOAdditions.h"
#import "ScheduleDetailTableView.h"
#import "ScheduleEventWrapper.h"
#import <QuartzCore/QuartzCore.h>
#import "Note.h"
#import "CoreDataManager.h"

#define TABLE_TAG 1

@implementation ScheduleTabletTableViewCell

@synthesize event, isFirstInSection, parentViewController;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentMode = UIViewContentModeRedraw;
        
        CGRect frame = CGRectMake(self.frame.size.width - 40, -2, 30, 40);
        
        _bookmarkView = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        _bookmarkView.frame = frame;
        _bookmarkView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [self.contentView addSubview:_bookmarkView];
        
        self.textLabel.font = [UIFont fontWithName:@"Georgia" size:18];
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.detailTextLabel.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)addBookmark:(id)sender;
{
    ScheduleDetailTableView *detailTV = (ScheduleDetailTableView *)[self.contentView viewWithTag:TABLE_TAG];
    [detailTV.event addBookmark];
    [_bookmarkView setImage:[UIImage imageWithPathName:@"common/bookmark-ribbon-on"] forState:UIControlStateNormal];
    [_bookmarkView removeTarget:self action:@selector(addBookmark:) forControlEvents:UIControlEventTouchUpInside];
    [_bookmarkView addTarget:self action:@selector(removeBookmark:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)attemptToAddBookmark:(id)sender
{
    UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:nil
                                                         message:@"Bookmarking this event will only add it to your personal schedule.  You will still need to register for it to attend."
                                                        delegate:self
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil] autorelease];
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [self addBookmark:nil];
}

- (void)removeBookmark:(id)sender
{
    ScheduleDetailTableView *detailTV = (ScheduleDetailTableView *)[self.contentView viewWithTag:TABLE_TAG];
    [detailTV.event removeBookmark];
    [_bookmarkView setImage:[UIImage imageWithPathName:@"common/bookmark-ribbon-off"] forState:UIControlStateNormal];
    [_bookmarkView removeTarget:self action:@selector(removeBookmark:) forControlEvents:UIControlEventTouchUpInside];
    [_bookmarkView addTarget:self action:@selector(addBookmark:) forControlEvents:UIControlEventTouchUpInside];
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
    
    // i have not figured out why the table view cells
    // end up being so much narrower than their frame
    CGRect textLabelFrame = self.textLabel.frame;
    textLabelFrame.origin.x = -10;
    
    CGRect detailLabelFrame = self.detailTextLabel.frame;
    detailLabelFrame.origin.x = -10;

    [_bookmarkView removeTarget:NULL action:NULL forControlEvents:UIControlEventTouchUpInside];
    
    if (self.scheduleCellType == ScheduleCellLastInTable || self.scheduleCellType == ScheduleCellSelected) {
        
        // make sure textLabel and detailTextLabel are still positioned at the top
        CGFloat gap = detailLabelFrame.origin.y - textLabelFrame.origin.y;
        textLabelFrame.origin.y = 10;
        detailLabelFrame.origin.y = textLabelFrame.origin.y + gap;
        
        // activate bookmark view
        if ([self.event isRegistered]) {
            [_bookmarkView addTarget:self action:@selector(refuseToRemoveBookmark:) forControlEvents:UIControlEventTouchUpInside];
        } else if ([self.event isBookmarked]) {
            [_bookmarkView addTarget:self action:@selector(removeBookmark:) forControlEvents:UIControlEventTouchUpInside];
        } else if ([self.event registrationURL]) {
            [_bookmarkView addTarget:self action:@selector(attemptToAddBookmark:) forControlEvents:UIControlEventTouchUpInside];
        } else {
            [_bookmarkView addTarget:self action:@selector(addBookmark:) forControlEvents:UIControlEventTouchUpInside];
        }

        // activate note view
        UIButton *notesButton = (UIButton *)[self.contentView viewWithTag:4348];
        if (!notesButton) {
            UIImage *notesImage = [UIImage imageWithPathName:@"modules/schedule/list-note.png"];
            UIButton *notesButton = [UIButton buttonWithType:UIButtonTypeCustom];
            notesButton.tag = 4348;
            [notesButton setImage:notesImage forState:UIControlStateNormal];
            notesButton.frame = CGRectMake(self.frame.size.width - 100, -4, notesImage.size.width, notesImage.size.height);
            [notesButton addTarget:self action:@selector(noteButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            notesButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            [self.contentView addSubview:notesButton];
        }
    }

    self.textLabel.frame = textLabelFrame;
    self.detailTextLabel.frame = detailLabelFrame;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();

    // rounded corner code from 
    // http://stackoverflow.com/questions/1331632/uitableviewcell-rounded-corners-and-clip-subviews
    CGFloat radius = 8;
    
    CGFloat minx = CGRectGetMinX(rect) + 10;
    CGFloat midx = CGRectGetMidX(rect);
    CGFloat maxx = CGRectGetMaxX(rect) - 10;
    CGFloat miny = CGRectGetMinY(rect);
    CGFloat midy = CGRectGetMidY(rect);
    CGFloat maxy = CGRectGetMaxY(rect);

    // fill out what looks like a continuation of the cell above
    if (self.isFirstInSection) {
        CGFloat components[4] = { 12.0/255.0, 10.0/255.0, 9.0/255.0, 1.0 };
        CGContextSetFillColor(context, components);
        CGRect innerRect = CGRectMake(minx, miny, maxx-minx, maxy-miny);
        CGContextFillRect(context, innerRect);
        
    } else {
        CGFloat components[4] = { 216.0/255.0, 217.0/255.0, 216.0/255.0, 1.0 };
        CGContextSetFillColor(context, components);
        CGRect innerRect = CGRectMake(minx, miny, maxx-minx, maxy-miny);
        CGContextFillRect(context, innerRect);
        
        // stroke the sides.
        CGFloat borderComponents[4] = { 0.3, 0.3, 0.3, 1 };
        CGContextSetStrokeColor(context, borderComponents);
        
        CGContextMoveToPoint(context, minx, miny);
        CGContextAddLineToPoint(context, minx, maxy);
        CGContextStrokePath(context);
        
        CGContextMoveToPoint(context, maxx, miny);
        CGContextAddLineToPoint(context, maxx, maxy);
        CGContextStrokePath(context);
    }

    // draw our own cell
    CGContextBeginPath(context);
    
    if (self.scheduleCellType == ScheduleCellSelected) {
        CGFloat components[4] = { 1, 1, 1, 1 };
        CGContextSetFillColor(context, components);
    } else {
        CGFloat components[4] = { 216.0/255.0, 217.0/255.0, 216.0/255.0, 1.0 };
        CGContextSetFillColor(context, components);
    }
    
    if (self.scheduleCellType == ScheduleCellLastInTable) {
        // draw rounded corners on four sides
        CGContextMoveToPoint(context, minx, midy);
        CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
        CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
        CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
        CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
        
    } else {
        // draw two rounded corners at the top.
        CGContextMoveToPoint(context, minx, maxy);
        CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
        CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
        CGContextAddLineToPoint(context, maxx, maxy);
        CGContextAddLineToPoint(context, minx, maxy);
    }
    
    CGContextClip(context);
    CGContextFillRect(context, rect);
    
    if (self.scheduleCellType == ScheduleCellLastInTable) {
        // stroke entire border
        CGContextMoveToPoint(context, minx, midy);
        CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
        CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
        CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
        CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
        CGContextClosePath(context);
        CGContextStrokePath(context);

    } else {
        // stroke the top and sides.
        CGContextMoveToPoint(context, minx, maxy);
        CGContextAddLineToPoint(context, minx, midy);
        CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
        CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
        CGContextAddLineToPoint(context, maxx, maxy);
        CGContextStrokePath(context);
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
    self.event = nil;
    self.parentViewController = nil;
    [_bookmarkView release];
    [super dealloc];
}

#pragma mark Notes

- (void)noteButtonPressed:(id)sender
{
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"title = %@ AND eventIdentifier = %@", self.event.title, event.identifier];
    Note *note = [[[CoreDataManager sharedManager] objectsForEntity:NotesEntityName matchingPredicate:pred] lastObject];
    
    NSDate * dateForNote = [NSDate date];
    
    if (nil != note)
        if (nil != note.date)
            dateForNote = note.date;
    
    _noteViewController = [[[NewNoteViewController alloc] initWithTitleText:self.event.title
                                                                       date:dateForNote              
                                                                andDateText:[Note dateToDisplay:dateForNote]
                                                                    eventId:event.identifier
                                                                  viewWidth:NEWNOTE_WIDTH 
                                                                 viewHeight:NEWNOTE_HEIGHT] retain];
    _noteViewController.viewControllerBackground = self;
    
    UINavigationController *navC = [[[UINavigationController alloc] initWithRootViewController:_noteViewController] autorelease];
    
    UIBarButtonItem *item = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                           target:self
                                                                           action:@selector(dismissModalViewControllerAnimated:)] autorelease];
    
    _noteViewController.navigationItem.rightBarButtonItem = item;
    
    navC.modalPresentationStyle =  UIModalPresentationFormSheet;
    navC.navigationBar.tintColor = [UIColor blackColor];
    [self.parentViewController presentModalViewController:navC animated:YES];
    
    CGRect frame = navC.view.superview.frame;
    frame.size.width = NEWNOTE_WIDTH;
    navC.view.superview.frame = frame;
    
}

-(void) saveNotesState {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"title = %@ AND date = %@", _noteViewController.titleText, _noteViewController.date];
    Note *note = [[[CoreDataManager sharedManager] objectsForEntity:NotesEntityName matchingPredicate:pred] lastObject];
    
    if (nil == note) {
        note = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:NotesEntityName];
    }
    
    note.title = _noteViewController.titleText;
    note.date = _noteViewController.date;
    note.details = _noteViewController.textViewString;
    
    if (nil != _noteViewController.eventIdentifier)
        note.eventIdentifier = _noteViewController.eventIdentifier;
    
    [[CoreDataManager sharedManager] saveData];
}

- (void) dismissModalViewControllerAnimated:(BOOL)animated {
    
    if (nil != _noteViewController) {
        [self saveNotesState];
        _noteViewController = nil;
    }
    
    [self.parentViewController dismissModalViewControllerAnimated:YES];
}

#pragma mark NotesModalViewDelegate 

-(void) deleteNoteWithoutSaving {
    if (nil != _noteViewController) {
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"title = %@ AND date = %@", _noteViewController.titleText, _noteViewController.date];
        Note *note = [[[CoreDataManager sharedManager] objectsForEntity:NotesEntityName matchingPredicate:pred] lastObject];
        
        if (nil != note) {
            [[CoreDataManager sharedManager] deleteObject:note];
            [[CoreDataManager sharedManager] saveData];
        }
        _noteViewController = nil;
    }
    [self.parentViewController dismissModalViewControllerAnimated:YES];
}

@end


@implementation ScheduleTabletSectionHeaderCell

@synthesize isFirst;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellEditingStyleNone;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect frame = self.textLabel.frame;
    frame.origin.x = -10;
    self.textLabel.frame = frame;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    NSLog(@"superview: %@", self.superview);
    NSLog(@"rect: %.1f %.1f %.1f %.1f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    
    CGContextRef context = UIGraphicsGetCurrentContext();

    // draw two rounded corners at the top
    
    CGFloat radius = 8;
    
    CGFloat minx = CGRectGetMinX(rect) + 10;
    CGFloat midx = CGRectGetMidX(rect);
    CGFloat maxx = CGRectGetMaxX(rect) - 10;
    CGFloat miny = CGRectGetMinY(rect);
    CGFloat midy = CGRectGetMidY(rect);
    CGFloat maxy = CGRectGetMaxY(rect);
    
    if (!self.isFirst) {
        // fill out what looks like a continuation of the cell above
        CGRect innerRect = CGRectMake(minx, miny, maxx-minx, maxy-miny);

        CGFloat components[4] = { 216.0/255.0, 217.0/255.0, 216.0/255.0, 1.0 };
        CGContextSetFillColor(context, components);
        CGContextFillRect(context, innerRect);
        
        // stroke the sides.
        components[0] = components[1] = components[2] = 0.3;
        CGContextMoveToPoint(context, minx, miny);
        CGContextAddLineToPoint(context, minx, maxy);
        CGContextStrokePath(context);
        
        CGContextMoveToPoint(context, maxx, miny);
        CGContextAddLineToPoint(context, maxx, maxy);
        CGContextStrokePath(context);
    }
    
    CGContextBeginPath(context);
    
    CGContextMoveToPoint(context, minx, maxy);
    CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
    CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
    CGContextAddLineToPoint(context, maxx, maxy);
    CGContextAddLineToPoint(context, minx, maxy);

    CGContextClip(context);
    
    // vertical gradient
    
    CGFloat locations[2] = { 0.0, 1.0 };
    CGFloat components[8] = { 
        44.0/255.0, 41.0/255.0, 38.0/255.0, 1.0,
        12.0/255.0, 10.0/255.0, 9.0/255.0, 1.0 };
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, components, locations, 2);
    
    CGPoint startPoint = CGPointMake(CGRectGetMidX(rect), 0);
    CGPoint endPoint = CGPointMake(CGRectGetMidX(rect), rect.size.height);
    
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    CGColorSpaceRelease(colorSpace);
    CGGradientRelease(gradient);

}


@end







