#import "PhotosModule.h"
#import "FacebookPhotosViewController.h"
#import "FacebookPhotoDetailViewController.h"
#import "PhotoUploadViewController.h"
#import "KGOSocialMediaController.h"
#import "KGOHomeScreenWidget.h"
#import "KGOTheme.h"

NSString * const LocalPathPageNamePhotoUpload = @"uploadPhoto";

@implementation PhotosModule

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params {
    UIViewController *vc = nil;
    
    NSString *homeNibName;
    NSString *detailNibName;
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        homeNibName = @"FacebookMediaViewController";
        detailNibName = @"FacebookMediaDetailViewController";
    } else {
        homeNibName = @"FacebookMediaViewController-iPad";
        detailNibName = @"FacebookMediaDetailViewController-iPad";
    }
    
    if ([pageName isEqualToString:LocalPathPageNameHome]) {
        vc = [[[FacebookPhotosViewController alloc] initWithNibName:homeNibName bundle:nil] autorelease];
    } else if ([pageName isEqualToString:LocalPathPageNameDetail]) {
        FacebookPhoto *photo = [params objectForKey:@"photo"];
        if (photo) {
            vc = [[[FacebookPhotoDetailViewController alloc] initWithNibName:detailNibName bundle:nil] autorelease];
            NSArray *photos = [params objectForKey:@"photos"];
            NSInteger index = [photos indexOfObject:photo];
            [(FacebookPhotoDetailViewController *)vc setPosts:photos];
            [(FacebookPhotoDetailViewController *)vc setInitialIndex:index];
            [(FacebookPhotoDetailViewController *)vc setModuleTag:PhotosTag];
        }
    } else if ([pageName isEqualToString:LocalPathPageNamePhotoUpload]) {
        UIImage *image = [params objectForKey:@"photo"];
        NSString *profile = [params objectForKey:@"profile"];
        FacebookPhotosViewController *photosVC = [params objectForKey:@"parentVC"];
        if (image && profile && photosVC) {
            PhotoUploadViewController *uploadVC = [[[PhotoUploadViewController alloc] initWithNibName:@"PhotoUploadViewController"
                                                                                               bundle:nil] autorelease];
            uploadVC.profile = profile;
            uploadVC.photo = image;
            uploadVC.parentVC = photosVC;
            
            vc = uploadVC;
        }
    }
    return vc;
}

- (void)launch {
    [super launch];
    [[KGOSocialMediaController facebookService] startup];
}

- (void)terminate {
    [super terminate];
    [[KGOSocialMediaController facebookService] shutdown];
}

#pragma mark View on home screen


#pragma mark Social media controller

- (NSSet *)socialMediaTypes {
    return [NSSet setWithObject:KGOSocialMediaTypeFacebook];
}

- (NSDictionary *)userInfoForSocialMediaType:(NSString *)mediaType {
    if ([mediaType isEqualToString:KGOSocialMediaTypeFacebook]) {
        return [NSDictionary dictionaryWithObject:[NSArray arrayWithObjects:
                                                   @"read_stream",
                                                   //@"offline_access",
                                                   @"user_groups",
                                                   @"user_photos",
                                                   @"publish_stream",
                                                   nil]
                                           forKey:@"permissions"];
    }
    return nil;
}

@end
