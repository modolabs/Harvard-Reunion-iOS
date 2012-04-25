
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import "ScheduleTabletTableViewCell.h"
#import "UIKit+KGOAdditions.h"
#import "ScheduleDetailTableView.h"
#import "ScheduleEventWrapper.h"
#import <QuartzCore/QuartzCore.h>
#import "Note.h"
#import "CoreDataManager.h"

#define TABLE_TAG 1
#define BOOKMARK_OK_ALERTVIEW 456

@implementation ScheduleTabletTableViewCell

@synthesize event, isFirstInSection, isAfterSelected, parentViewController;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentMode = UIViewContentModeRedraw;
        
        UIImage *image = [UIImage imageWithPathName:@"common/bookmark-ribbon-on"];
        CGRect frame = CGRectMake(self.frame.size.width - 80, -2, image.size.width, image.size.height);
        
        _bookmarkView = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        _bookmarkView.frame = frame;
        _bookmarkView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [self.contentView addSubview:_bookmarkView];
        
        UIImage *notesImage = [UIImage imageWithPathName:@"modules/schedule/list-note.png"];
        _notesButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        [_notesButton addTarget:self action:@selector(noteButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        _notesButton.frame = CGRectMake(self.frame.size.width - 130, 0, notesImage.size.width, notesImage.size.height);
        _notesButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [self.contentView addSubview:_notesButton];
        
        
        self.textLabel.font = [UIFont fontWithName:@"Georgia" size:18];
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.detailTextLabel.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)addBookmark;
{
    [self.event addBookmark];
    [_bookmarkView setImage:[UIImage imageWithPathName:@"common/bookmark-ribbon-on"] forState:UIControlStateNormal];
    [_bookmarkView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [_bookmarkView addTarget:self action:@selector(attemptToRemoveBookmark:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)attemptToAddBookmark:(id)sender
{
    if ([self.event registrationRequired]) {
        UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:nil
                                                             message:@"Bookmarking this event will only add it to your personal schedule.  You will still need to register for it to attend."
                                                            delegate:self
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil] autorelease];
        alertView.tag = BOOKMARK_OK_ALERTVIEW;
        [alertView show];
        
    } else {
        [self addBookmark];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == BOOKMARK_OK_ALERTVIEW) {
        [self addBookmark];
    }
}

- (void)attemptToRemoveBookmark:(id)sender
    {
    if ([self.event isRegistered]) {
        UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:nil
                                                             message:@"Events you have registered for cannot be removed from your schedule."
                                                            delegate:nil
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil] autorelease];
        [alertView show];
        
    } else {
        [self.event removeBookmark];
        [_bookmarkView setImage:[UIImage imageWithPathName:@"common/bookmark-ribbon-off"] forState:UIControlStateNormal];
        [_bookmarkView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [_bookmarkView addTarget:self action:@selector(attemptToAddBookmark:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGRect textLabelFrame = self.textLabel.frame;
    CGRect detailLabelFrame = self.detailTextLabel.frame;
    CGFloat gap = detailLabelFrame.origin.y - textLabelFrame.origin.y - textLabelFrame.size.height;

    textLabelFrame.origin.y = 10;
    textLabelFrame.origin.x = 10;
    detailLabelFrame.origin.x = 10;
    
    if (!_notesButton.hidden) {
        // leave room for notes icons
        textLabelFrame.size.width = self.frame.size.width - 150;
        detailLabelFrame.size.width = self.frame.size.width - 150;
    } else if (!_bookmarkView.hidden) {
        // leave room for bookmark icons
        textLabelFrame.size.width = self.frame.size.width - 90;
        detailLabelFrame.size.width = self.frame.size.width - 90;
    } else {
        textLabelFrame.size.width = self.bounds.size.width - 30;
        detailLabelFrame.size.width = self.bounds.size.width - 30;
    }
    
    // Allow for multiline titles when selected
    self.textLabel.numberOfLines = (self.isLast || self.isSelected) ? 3 : 1;
    self.textLabel.lineBreakMode = UILineBreakModeTailTruncation;
        
    CGSize maxSize = CGSizeMake(textLabelFrame.size.width, self.textLabel.font.lineHeight * self.textLabel.numberOfLines);
    CGSize textLabelSize = [self.textLabel.text sizeWithFont:self.textLabel.font
                                           constrainedToSize:maxSize
                                               lineBreakMode:UILineBreakModeTailTruncation];
    textLabelFrame.size.height = textLabelSize.height;
    detailLabelFrame.origin.y = textLabelFrame.origin.y + textLabelFrame.size.height + gap;
    
    // adjust map view and detail view
    UIView *detailsView = [self viewWithTag:DETAILS_VIEW_TAG];
    UIView *mapView = [self viewWithTag:MAP_VIEW_TAG];
    
    CGRect detailsViewFrame = detailsView.frame;
    CGFloat detailsY = detailLabelFrame.origin.y + detailLabelFrame.size.height;
    detailsViewFrame.origin.y = detailsY;
    detailsViewFrame.size.height = self.frame.size.height - detailsY;
    detailsView.frame = detailsViewFrame;
    
    CGRect mapViewFrame = mapView.frame;
    CGFloat mapY = detailLabelFrame.origin.y + detailLabelFrame.size.height + 10;
    mapViewFrame.origin.y = mapY;
    mapViewFrame.size.height = self.frame.size.height - mapY - 10;
    mapView.frame = mapViewFrame;
    
    self.textLabel.frame = textLabelFrame;
    self.detailTextLabel.frame = detailLabelFrame;

    [_bookmarkView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    _bookmarkView.userInteractionEnabled = self.isSelected;
    _notesButton.userInteractionEnabled = self.isSelected;

    if (self.isLast || self.isSelected) {
        // activate bookmark view
        if ([self.event isRegistered] || [self.event isBookmarked]) { // bookmarked or registered (handler checks)
            [_bookmarkView addTarget:self action:@selector(attemptToRemoveBookmark:) forControlEvents:UIControlEventTouchUpInside];
            
        } else { // not bookmarked (handler checks registration)
            [_bookmarkView addTarget:self action:@selector(attemptToAddBookmark:) forControlEvents:UIControlEventTouchUpInside];
        }
                
        ScheduleDetailTableView *tableView = (ScheduleDetailTableView *)[self.contentView viewWithTag:TABLE_TAG];
        [tableView flashScrollIndicators];
    }
    
    // activate note view
    if ([self.event note]) {
        [_notesButton setImage:[UIImage imageWithPathName:@"modules/schedule/list-note.png"] forState:UIControlStateNormal];
        
    } else {
        [_notesButton setImage:[UIImage imageWithPathName:@"modules/schedule/list-note-off.png"] forState:UIControlStateNormal];
    }

}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    
    if (self.isSelected)
        return;

    if (highlighted) {
        self.textLabel.textColor = [UIColor whiteColor];
        self.detailTextLabel.textColor = [UIColor whiteColor];
    } else {
        self.textLabel.textColor = [UIColor blackColor];
        self.detailTextLabel.textColor = [UIColor grayColor];
    }
    
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();

    // rounded corner code from 
    // http://stackoverflow.com/questions/1331632/uitableviewcell-rounded-corners-and-clip-subviews
    CGFloat radius = 8;
    
    CGFloat minx = CGRectGetMinX(rect);
    CGFloat midx = CGRectGetMidX(rect);
    CGFloat maxx = CGRectGetMaxX(rect) - 10;
    CGFloat miny = CGRectGetMinY(rect);
    CGFloat midy = CGRectGetMidY(rect);
    CGFloat maxy = CGRectGetMaxY(rect);

    // fill out what looks like a continuation of the cell above
    if (self.isFirstInSection) {
        CGFloat components[4] = { 12.0/255.0, 10.0/255.0, 9.0/255.0, 1.0 };
        CGContextSetFillColor(context, components);
        CGRect innerRect = CGRectMake(minx, miny, maxx-minx, midy-miny);
        CGContextFillRect(context, innerRect);
        
    } else {
        if (self.isAfterSelected) {
            CGFloat components[4] = { 1.0, 1.0, 1.0, 1.0 };
            CGContextSetFillColor(context, components);
        } else {
            CGFloat components[4] = { 216.0/255.0, 217.0/255.0, 216.0/255.0, 1.0 };
            CGContextSetFillColor(context, components);
        }
        CGRect innerRect = CGRectMake(minx, miny, maxx-minx, midy-miny);
        CGContextFillRect(context, innerRect);
        
        // stroke the sides.        
        CGContextMoveToPoint(context, minx, miny);
        CGContextAddLineToPoint(context, minx, midy);
        CGContextStrokePath(context);
        
        CGContextMoveToPoint(context, maxx, miny);
        CGContextAddLineToPoint(context, maxx, midy);
        CGContextStrokePath(context);
    }

    // draw our own cell
    CGContextBeginPath(context);
    
    if (self.isSelected) {
        CGFloat components[4] = { 1, 1, 1, 1 };
        CGContextSetFillColor(context, components);
    } else if (self.highlighted) {
        CGFloat components[4] = { 0.5, 0.5, 0.5, 1 };
        CGContextSetFillColor(context, components);
    } else {
        CGFloat components[4] = { 216.0/255.0, 217.0/255.0, 216.0/255.0, 1.0 };
        CGContextSetFillColor(context, components);
    }
    
    if (self.isLast) {
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
    
    if (self.isLast) {
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

- (UIButton *)notesButton
{
    return _notesButton;
}

- (BOOL)isLast
{
    return _isLast;
}

- (void)setIsLast:(BOOL)isLast
{
    if (isLast != _isLast) {
        _isLast = isLast;
        
        [self setNeedsLayout];
    }
}

- (BOOL)isSelected
{
    return _isSelected;
}

- (void)setIsSelected:(BOOL)isSelected
{
    if (isSelected != _isSelected) {
        _isSelected = isSelected;
        
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
    NSDate * dateForNote = [NSDate date];
    
    Note *note = [self.event note];
    
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
    navC.navigationBar.barStyle = UIBarStyleBlack;
    [self.parentViewController presentModalViewController:navC animated:YES];
    
    CGRect frame = navC.view.superview.frame;
    frame.size.width = NEWNOTE_WIDTH;
    navC.view.superview.frame = frame;
    
}

-(void) saveNotesState {
    Note *note = [self.event note];
    
    if (nil == note) {
        note = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:NotesEntityName];
    }
    
    note.title = _noteViewController.titleText;
    note.date = _noteViewController.date;
    note.details = _noteViewController.textViewString;
    
    if (nil != _noteViewController.eventIdentifier)
        note.eventIdentifier = _noteViewController.eventIdentifier;
    
    [[CoreDataManager sharedManager] saveData];
    
    [self setNeedsLayout];
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
    
    [self setNeedsLayout];
}

@end


@implementation ScheduleTabletSectionHeaderCell

@synthesize isFirst, isAfterSelected;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect frame = self.textLabel.frame;
    frame.origin.x = 10;
    frame.size.width = self.bounds.size.width - 30;
    self.textLabel.frame = frame;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    DLog(@"superview: %@", self.superview);
    DLog(@"rect: %.1f %.1f %.1f %.1f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    
    CGContextRef context = UIGraphicsGetCurrentContext();

    // draw two rounded corners at the top
    
    CGFloat radius = 8;
    
    CGFloat minx = CGRectGetMinX(rect);
    CGFloat midx = CGRectGetMidX(rect);
    CGFloat maxx = CGRectGetMaxX(rect) - 10;
    CGFloat miny = CGRectGetMinY(rect);
    CGFloat midy = CGRectGetMidY(rect);
    CGFloat maxy = CGRectGetMaxY(rect);
    
    if (!self.isFirst) {
        // fill out what looks like a continuation of the cell above
        CGRect innerRect = CGRectMake(minx, miny, maxx-minx, midy-miny);

        if (self.isAfterSelected) {
            CGFloat components[4] = { 1.0, 1.0, 1.0, 1.0 };
            CGContextSetFillColor(context, components);
        } else {
            CGFloat components[4] = { 216.0/255.0, 217.0/255.0, 216.0/255.0, 1.0 };
            CGContextSetFillColor(context, components);
        }
        CGContextFillRect(context, innerRect);
        
        // stroke the sides.
        CGContextMoveToPoint(context, minx, miny);
        CGContextAddLineToPoint(context, minx, midy);
        CGContextStrokePath(context);
        
        CGContextMoveToPoint(context, maxx, miny);
        CGContextAddLineToPoint(context, maxx, midy);
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







