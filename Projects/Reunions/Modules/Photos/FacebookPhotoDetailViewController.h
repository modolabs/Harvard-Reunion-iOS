
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import "FacebookMediaDetailViewController.h"

@class FacebookPhoto;

@interface FacebookPhotoDetailViewController : FacebookMediaDetailViewController <ConnectionWrapperDelegate> {
    
    //MITThumbnailView *_thumbnail;
}

@property (nonatomic, retain) FacebookPhoto *photo;
@property (nonatomic, retain) ConnectionWrapper *connection;
@property (nonatomic, retain) NSURL *currentURL;

@end