#import "KGOSocialMediaController.h"
#import "KGOFacebookService.h"

extern NSString * const FacebookDidGetSelfInfoNotification;

@class FacebookPost, FacebookParentPost, FacebookUser;

// TODO: add failure delegate methods

@protocol FacebookPhotoUploadDelegate <NSObject>

- (void)didUploadPhoto:(id)result;

@end

@protocol FacebookUploadDelegate <NSObject>

- (void)uploadDidComplete:(FacebookPost *)result;
//- (void)uploadDidFail:(NSDictionary *)params;

@end

@interface KGOFacebookService (FacebookAPI)

- (BOOL)requestFacebookGraphPath:(NSString *)graphPath receiver:(id)receiver callback:(SEL)callback;
- (BOOL)requestFacebookFQL:(NSString *)query receiver:(id)receiver callback:(SEL)callback;

// TODO: as with other POST methods, have these follow the upload delegate convention
- (BOOL)likeFacebookPost:(FacebookParentPost *)post receiver:(id)receiver callback:(SEL)callback;
- (BOOL)unlikeFacebookPost:(FacebookParentPost *)post receiver:(id)receiver callback:(SEL)callback;

- (BOOL)addComment:(NSString *)comment toFacebookPost:(FacebookParentPost *)post delegate:(id<FacebookUploadDelegate>)delegate;
- (BOOL)uploadPhoto:(UIImage *)photo
  toFacebookProfile:(NSString *)graphPath
            message:(NSString *)caption
           delegate:(id<FacebookUploadDelegate>)delegate;

- (BOOL)postStatus:(NSString *)message toProfile:(NSString *)profile delegate:(id<FacebookUploadDelegate>)delegate;

- (NSString *)imageURLForGraphObject:(NSString *)graphID;

- (void)disconnectFacebookRequests:(id)receiver;

- (FacebookUser *)currentFacebookUser;

@end
