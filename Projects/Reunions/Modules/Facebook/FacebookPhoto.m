
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import "FacebookPhoto.h"
#import "Foundation+KGOAdditions.h"
#import "CoreDataManager.h"
#import "FacebookModule.h"
#import "FacebookUser.h"
#import "FacebookComment.h"

NSString * const FacebookPhotoEntityName = @"FacebookPhoto";

NSInteger widthSort(id imageDict1, id imageDict2, void *context);

@implementation FacebookPhoto
@dynamic src;
@dynamic data;
@dynamic width;
@dynamic title;
@dynamic height;
@dynamic thumbData;

@synthesize thumbSrc = _thumbSrc;

+ (FacebookPhoto *)photoWithID:(NSString *)identifier {
    identifier = [NSString stringWithFormat:@"%@", identifier]; // in case it comes from the json as a number or something
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"identifier like %@", identifier];
    FacebookPhoto *photo = [[[CoreDataManager sharedManager] objectsForEntity:FacebookPhotoEntityName
                                                            matchingPredicate:pred] lastObject];
    if (!photo) {
        photo = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:FacebookPhotoEntityName];
        photo.identifier = identifier;
    }
    return photo;
}

+ (FacebookPhoto *)photoWithDictionary:(NSDictionary *)dictionary size:(FacebookPhotoSize)size {
    
    FacebookPhoto *photo = nil;
    id identifier = [dictionary objectForKey:@"object_id"]; // via feed or FQL
    if (!identifier) {
        identifier = [dictionary objectForKey:@"id"]; // via Photo Graph API
    }
    // not sure yet if this is a string or number or if anything else is possible
    NSLog(@"object_id is %@ of type %@", identifier, [[identifier class] description]);
    
    if (identifier) {
        photo = [FacebookPhoto photoWithID:identifier];
        [photo updateWithDictionary:dictionary size:size];
    }
    
    return photo;
}

- (void)updateWithDictionary:(NSDictionary *)dictionary size:(FacebookPhotoSize)size {
    
    NSString *theSrc = [dictionary stringForKey:@"source" nilIfEmpty:YES]; // from Graph API
    if(!theSrc) {
        theSrc = [dictionary stringForKey:@"picture" nilIfEmpty:YES]; // from feed
    }
    if (!theSrc) {
        theSrc = [dictionary objectForKey:@"src"]; // from FQL
    }
    if (![theSrc isEqualToString:self.src]) {
        self.src = theSrc;
    }
    
    // TODO: decide if we're using created_time (created) or updated_time (modified)
    NSString *createdTime = [dictionary stringForKey:@"created_time" nilIfEmpty:YES]; // graph
    if (!createdTime) {
        createdTime = [dictionary stringForKey:@"created" nilIfEmpty:YES]; // fql
    }
    if (createdTime) {
        // graph API returns RFC3339 strings
        NSDate *date = [FacebookModule dateFromRFC3339DateTimeString:createdTime];
        if (date && ![date isEqualToDate:self.date]) {
            self.date = date;
        }
    }
    
    // attributes that can change, or that we might get through different API's
    
    CGFloat width = [dictionary floatForKey:@"width"]; // graph
    if (!width) {
        width = [[dictionary objectForKey:@"src_width"] floatValue]; // fql
    }
    if (width) {
        self.width = [NSNumber numberWithFloat:width];
    }
    
    CGFloat height = [dictionary floatForKey:@"height"]; // graph
    if (!height) {
        height = [[dictionary objectForKey:@"src_height"] floatValue]; // fql
    }
    if (height) {
        self.height = [NSNumber numberWithFloat:height];
    }
    
    NSString *theTitle = [dictionary stringForKey:@"name" nilIfEmpty:YES]; // graph
    if (!theTitle) {
        theTitle = [dictionary stringForKey:@"caption" nilIfEmpty:YES]; // fql
    }
    if (![theTitle isEqualToString:self.title]) {
        self.title = theTitle;
    }
    
    NSString *owner = [dictionary objectForKey:@"owner"]; // fql
    NSDictionary *ownerDict = nil; // graph
    if (!owner) {
        ownerDict = [dictionary dictionaryForKey:@"from"];
        // TODO: remove this line which is just for type debugging
        owner = [ownerDict objectForKey:@"id"];
    }
    NSLog(@"owner is %@ of type %@", owner, [[owner class] description]);
    
    if (ownerDict) {
        self.owner = [FacebookUser userWithDictionary:ownerDict];
    } else if (owner) {
        owner = [NSString stringWithFormat:@"%@", owner];
        self.owner = [FacebookUser userWithID:owner];
    }
    
    if (!self.thumbData) {
        self.thumbSrc = [dictionary stringForKey:@"src_small" nilIfEmpty:YES]; // fql
        if (!self.thumbSrc) {
            // This currently assume the smallest image is tiny
            // and third smallest is medium
            NSArray *orderImages = [[dictionary arrayForKey:@"images"] sortedArrayUsingFunction:widthSort context:NULL];
            if (size == TINY) {
                NSDictionary *smallImage = [orderImages objectAtIndex:0];
                self.thumbSrc = [smallImage stringForKey:@"source" nilIfEmpty:YES];
            } else if(size == MEDIUM) {
                NSDictionary *mediumImage = [orderImages objectAtIndex:2];
                self.thumbSrc = [mediumImage stringForKey:@"source" nilIfEmpty:YES];
            }            
        }
    }
    
    NSDictionary *comments = [dictionary dictionaryForKey:@"comments"];
    if (comments) {
        NSArray *commentData = [comments arrayForKey:@"data"];
        for (NSDictionary *commentDict in commentData) {
            FacebookComment *aComment = [FacebookComment commentWithDictionary:commentDict];
            aComment.parent = self;
        }
    }
    
    NSDictionary *likes = [dictionary dictionaryForKey:@"likes"];
    if (likes) {
        //NSInteger count = [likes integerForKey:@"count"];
        for (NSDictionary *aLike in [likes arrayForKey:@"data"]) {
            FacebookUser *user = [FacebookUser userWithDictionary:aLike];
            NSMutableSet *set = [[self.likes mutableCopy] autorelease];
            [set addObject:user];
            self.likes = set;
        }
    }
}

#pragma mark FacebookThumbSource
- (NSString *)thumbnailSourceURLString {
    return _thumbSrc;
}

- (NSData *)mediaData {
    return self.data;
}

@end

NSInteger widthSort(id imageDict1, id imageDict2, void *context) {
    NSNumber *width1 = [imageDict1 numberForKey:@"width"];
    NSNumber *width2 = [imageDict2 numberForKey:@"width"];
    return [width1 compare:width2];
}
