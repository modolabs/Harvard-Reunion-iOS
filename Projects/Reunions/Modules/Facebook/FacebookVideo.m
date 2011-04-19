#import "FacebookVideo.h"
#import "Foundation+KGOAdditions.h"
#import "CoreDataManager.h"
#import "FacebookUser.h"
#import "FacebookComment.h"

NSString * const FacebookVideoEntityName = @"FacebookVideo";

@implementation FacebookVideo
@dynamic name;
@dynamic message;
@dynamic summary;
@dynamic thumbSrc;
@dynamic thumbData;
@dynamic link;
@dynamic src;

+ (FacebookVideo *)videoWithDictionary:(NSDictionary *)dictionary {
    FacebookVideo *video = nil;
    
    NSString *postIdentifier = nil;
    NSString *identifier = [dictionary objectForKey:@"id"]; // may be post ID (if from feed) or video ID (from direct video API)
    NSString *videoIdentifier = [dictionary objectForKey:@"object_id"]; // video ID from feed
    
    if (videoIdentifier) {
        postIdentifier = identifier;
        identifier = videoIdentifier;
    }
    
    if (identifier) {
        // force the id to be a string in case it's a number
        identifier = [NSString stringWithFormat:@"%@", identifier];
        video = [FacebookVideo videoWithID:identifier];
        video.postIdentifier = postIdentifier;

        video.thumbSrc = [dictionary stringForKey:@"picture" nilIfEmpty:YES];
        video.name = [dictionary stringForKey:@"name" nilIfEmpty:YES];
        video.src = [dictionary stringForKey:@"source" nilIfEmpty:YES];
        video.link = [dictionary stringForKey:@"link" nilIfEmpty:YES];
        video.message = [dictionary stringForKey:@"message" nilIfEmpty:YES];
        video.summary = [dictionary stringForKey:@"description" nilIfEmpty:YES];
        
        NSDictionary *owner = [dictionary dictionaryForKey:@"from"];
        video.owner = [FacebookUser userWithDictionary:owner];
        
        NSDictionary *likes = [dictionary dictionaryForKey:@"likes"];
        if (likes) {
            //NSInteger count = [likes integerForKey:@"count"];
            for (NSDictionary *aLike in [likes arrayForKey:@"data"]) {
                FacebookUser *user = [FacebookUser userWithDictionary:aLike];
                NSMutableSet *set = [[video.likes mutableCopy] autorelease];
                [set addObject:user];
                video.likes = set;
            }
        }
        
        NSDictionary *comments = [dictionary dictionaryForKey:@"comments"];
        if (comments) {
            //NSInteger count = [comments objectForKey:@"count"];
            for (NSDictionary *commentDict in [comments arrayForKey:@"data"]) {
                FacebookComment *aComment = [FacebookComment commentWithDictionary:commentDict];
                aComment.parent = video;
            }
        }
    }
    
    return video;
}

+ (FacebookVideo *)videoWithID:(NSString *)identifier {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"identifier like %@", identifier];
    FacebookVideo *aVideo = [[[CoreDataManager sharedManager] objectsForEntity:FacebookVideoEntityName matchingPredicate:pred] lastObject];
    if (!aVideo) {
        aVideo = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:FacebookVideoEntityName];
        aVideo.identifier = identifier;
    }
    return aVideo;
}

- (NSString *)videoSourceName {
    NSString *sourceName = nil;
    if ([self.src rangeOfString:@"youtube.com"].location != NSNotFound) {
        sourceName = @"YouTube";
    } else if([self.src rangeOfString:@"vimeo.com"].location != NSNotFound) {
        sourceName = @"Vimeo";
    }
    return sourceName;
}

#pragma mark FacebookThumbSource
- (NSString *)thumbnailSourceURLString {
    return self.thumbSrc;
}

- (NSString *)title {
    return self.name;
}

@end
