//
//  NewNoteViewController.m
//  Reunions
//
//  Created by Muhammad J Amjad on 4/16/11.
//  Copyright 2011 ModoLabs Inc. All rights reserved.
//

#import "NewNoteViewController.h"
#import "UIKit+KGOAdditions.h"
#import "KGOTheme.h"


@implementation NewNoteViewController
@synthesize textViewString;
@synthesize titleText;
@synthesize dateText;
@synthesize width;
@synthesize height;
@synthesize viewControllerBackground;

-(id) initWithTitleText: (NSString *) title andDateText: (NSString *) dateString  viewWidth: (double) viewWidth viewHeight: (double) viewHeight{
    
    self = [super init];
    
    if (self) {
        self.titleText = title;
        self.dateText = dateString;
        self.width = viewWidth;
        self.height = viewHeight;
    }
    
    return self;
}

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

#pragma mark - View lifecycle


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    [super loadView];
    
   /* UIButton * invisibleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    invisibleButton.frame = CGRectMake(0, 0, 1200, 1200);
    invisibleButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2f];
    [invisibleButton addTarget:self action:@selector(invisibleButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    invisibleButton.hidden = YES;
    //.enable = YES;*/
    
   // self.view.backgroundColor = [UIColor clearColor];
    
    /*UIView * invisible = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 1200, 1200)] autorelease];
    invisible.opaque = NO;
    invisible.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
  
    //[self.view addSubview:invisible];
    
    UIView * noteView = [[[UIView alloc] initWithFrame:CGRectMake(140, 75, 600, 675)] autorelease];
    noteView.backgroundColor = [UIColor yellowColor];*/
    
    UIFont *fontTitle = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyContentTitle];
    CGSize titleSize = [self.titleText sizeWithFont:fontTitle];
    UILabel * titleTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 5,  self.width- 10, titleSize.height + 5.0)];
    titleTextLabel.text = self.titleText;
    titleTextLabel.font = fontTitle;
    titleTextLabel.textColor = [UIColor blackColor];
    titleTextLabel.backgroundColor = [UIColor clearColor];
    
    UIFont *fontDetail = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyContentSubtitle];
    CGSize detailSize = [self.dateText sizeWithFont:fontTitle];
    UILabel * detailTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, titleTextLabel.frame.size.height + 10, self.width - 10, detailSize.height + 5.0)];
    detailTextLabel.text = self.dateText;
    detailTextLabel.font = fontDetail;
    detailTextLabel.textColor = [UIColor blackColor];
    detailTextLabel.backgroundColor = [UIColor clearColor];
    
    [self.view addSubview:titleTextLabel];
    [self.view addSubview:detailTextLabel];
    
    UIImage * image = [UIImage imageWithPathName:@"modules/schedule/faketop-above-selection.png"];
    UIImageView * sectionDivider;
    if (image){
        sectionDivider = [[UIImageView alloc] initWithImage:[image stretchableImageWithLeftCapWidth:0 topCapHeight:0]];
        sectionDivider.frame = CGRectMake(15, 
                                          titleTextLabel.frame.size.height + detailTextLabel.frame.size.height + 15, 
                                          self.width - 10, 
                                          4);
        
        [self.view addSubview:sectionDivider];
    }
    
    
    
    if (nil == textView) {
        
        textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 
                                                                titleTextLabel.frame.size.height + detailTextLabel.frame.size.height + 25, 
                                                                self.width, 
                                                                self.height - titleTextLabel.frame.size.height - detailTextLabel.frame.size.height - 25)];
        textView.backgroundColor = [UIColor clearColor];
        
        [self.view addSubview:textView];
        [textView becomeFirstResponder];
        textView.font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyByline];
    }
    
    //[self.view addSubview:noteView];
     self.view.backgroundColor = [UIColor yellowColor];
    
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
