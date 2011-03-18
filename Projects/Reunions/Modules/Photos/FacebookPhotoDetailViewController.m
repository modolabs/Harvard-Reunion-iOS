#import "FacebookPhotoDetailViewController.h"
#import "UIKit+KGOAdditions.h"
#import "Foundation+KGOAdditions.h"
#import "KGOSocialMediaController+FacebookAPI.h"
#import "KGOAppDelegate.h"
#import "FacebookModel.h"

@implementation FacebookPhotoDetailViewController

/*
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
 {
 self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
 if (self) {
 // Custom initialization
 }
 return self;
 }
 */
- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark -

- (void)displayPost {
    _thumbnail.imageURL = self.photo.src;
    _thumbnail.imageData = self.photo.data;
    [_thumbnail loadImage];
    
    if (!self.photo.comments.count) {
        [self getCommentsForPost];
    }
}

- (void)setPhoto:(FacebookPhoto *)photo {
    self.post = photo;
}

- (FacebookPhoto *)photo {
    return (FacebookPhoto *)self.post;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Photo";
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

#pragma mark - Table view methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.photo.title;
    //return [NSString stringWithFormat:@"x users like this"];
}

@end
