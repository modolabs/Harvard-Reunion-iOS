#import "ScheduleDetailTableView.h"
#import "KGOSocialMediaController+Foursquare.h"
#import "KGOFoursquareEngine.h"
#import "UIKit+KGOAdditions.h"

@implementation ScheduleDetailTableView

- (void)foursquareButtonPressed:(id)sender
{
    [[KGOSocialMediaController sharedController] startupFoursquare];
    [[KGOSocialMediaController sharedController] loginFoursquare];
}

- (void)facebookButtonPressed:(id)sender
{
}

- (void)headerViewFrameDidChange:(KGODetailPageHeaderView *)headerView
{
    CGRect frame = _facebookButton.frame;
    frame.origin.x = 10;
    frame.origin.y = _headerView.frame.size.height;
    if (_descriptionLabel) {
        frame.origin.y += _descriptionLabel.frame.size.height + 10;
    }
    _facebookButton.frame = frame;
    
    frame.origin.x += _facebookButton.frame.size.width + 10;
    _foursquareButton.frame = frame;
    
    frame = _headerView.frame;
    if (_descriptionLabel) {
        frame.size.height += _descriptionLabel.frame.size.height;
    }
    frame.size.height += _foursquareButton.frame.size.height + 20;
    
    if (frame.size.height != self.tableHeaderView.frame.size.height) {
        self.tableHeaderView.frame = frame;
        
        frame = _descriptionLabel.frame;
        frame.origin.y = _headerView.frame.size.height;
        _descriptionLabel.frame = frame;
        
        self.tableHeaderView = self.tableHeaderView;
    }
}

// TODO: use proper images for both 4square and fb
- (UIView *)viewForTableHeader
{
    UIView *containerView = [super viewForTableHeader];
    
    if (!_facebookButton) {
        _facebookButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        UIImage *image = [UIImage imageWithPathName:@"modules/facebook/button-facebook.png"];
        _facebookButton.frame = CGRectMake(0, 0, image.size.width, image.size.height);
        [_facebookButton setImage:image forState:UIControlStateNormal];
        [_facebookButton addTarget:self action:@selector(facebookButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    if (!_foursquareButton) {
        _foursquareButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        UIImage *image = [UIImage imageWithPathName:@"modules/foursquare/foursquare.jpg"];
        NSLog(@"foursquare image: %@", image);
        [_foursquareButton setImage:image forState:UIControlStateNormal];
        [_foursquareButton addTarget:self action:@selector(foursquareButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [containerView addSubview:_foursquareButton];
    [containerView addSubview:_facebookButton];
    
    NSLog(@"%@", containerView);
    NSLog(@"%@", _foursquareButton);
    NSLog(@"%@", _facebookButton);
    
    return containerView;
}

- (void)dealloc
{
    [_facebookButton release];
    [_foursquareButton release];
    [super dealloc];
}

@end
