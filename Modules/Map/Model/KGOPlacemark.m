#import "KGOPlacemark.h"
#import "KGOMapCategory.h"
#import "Foundation+KGOAdditions.h"
#import "CoreDataManager.h"
#import <CoreLocation/CoreLocation.h>
#import "KGOHTMLTemplate.h"

@implementation KGOPlacemark

@dynamic longitude;
@dynamic street;
@dynamic geometryType;
@dynamic title;
@dynamic latitude;
@dynamic identifier;
@dynamic geometry;
@dynamic info;
@dynamic sortOrder;
@dynamic photo;
@dynamic bookmarked;
@dynamic category;
@dynamic photoURL;

#pragma mark KGOSearchResult, MKAnnotation

- (NSString *)subtitle {
    return self.street;
}

- (CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake([self.latitude floatValue], [self.longitude floatValue]);
}

- (BOOL)isBookmarked {
    return [self.bookmarked boolValue];
}

- (void)addBookmark {
    if (![self isBookmarked]) {
        self.bookmarked = [NSNumber numberWithBool:YES];
    }
}

- (void)removeBookmark {
    if ([self isBookmarked]) {
        self.bookmarked = [NSNumber numberWithBool:NO];
    }
}

- (NSString *)moduleTag
{
    return MapTag;
}

#pragma mark -

+ (KGOPlacemark *)placemarkWithDictionary:(NSDictionary *)dictionary {
    NSArray *categoryPath = [dictionary arrayForKey:@"category"];
    NSString *theIdentifier = nil;
    id idObject = [dictionary objectForKey:@"id"];
    if ([idObject isKindOfClass:[NSString class]] || [idObject isKindOfClass:[NSNumber class]]) {
        theIdentifier = [idObject description];
    }
    NSLog(@"%@ %@", theIdentifier, [categoryPath componentsJoinedByString:@"/"]);
    
    KGOPlacemark *placemark = nil;
    if (categoryPath && theIdentifier) {
        KGOMapCategory *category = [KGOMapCategory categoryWithPath:categoryPath];
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"identifier like %@", theIdentifier];
        placemark = [[category.places filteredSetUsingPredicate:pred] anyObject];
        if (!placemark) {
            placemark = [[CoreDataManager sharedManager] insertNewObjectForEntityForName:KGOPlacemarkEntityName];
            placemark.identifier = theIdentifier;
            placemark.category = category;
        }
        
        placemark.title = [dictionary stringForKey:@"title" nilIfEmpty:YES];
        
        id descriptionInfo = [dictionary objectForKey:@"description"];
        if ([descriptionInfo isKindOfClass:[NSString class]] && [descriptionInfo length]) {
            placemark.info = descriptionInfo;
            
        } else if ([descriptionInfo isKindOfClass:[NSArray class]]) {
            KGOHTMLTemplate *itemTemplate = [[[KGOHTMLTemplate alloc] init] autorelease];
            // TODO: this is relying on the server returning "label" and "title"
            // for each field item, may not be robust
            itemTemplate.templateString = @"<li><strong>__label__:</strong>__title__</li>";
            placemark.info = [NSString stringWithFormat:@"<ul>%@</ul>", [itemTemplate stringWithMultiReplacements:descriptionInfo]];
        }
        
        CLLocationDegrees lat = [dictionary floatForKey:@"lat"];
        CLLocationDegrees lon = [dictionary floatForKey:@"lon"];
        if (lat || lon) {
            placemark.latitude = [NSNumber numberWithFloat:[dictionary floatForKey:@"lat"]];
            placemark.longitude = [NSNumber numberWithFloat:[dictionary floatForKey:@"lon"]];
        }

        placemark.photoURL = [dictionary stringForKey:@"photo" nilIfEmpty:YES];
        
        NSString *theGeometryType = [dictionary stringForKey:@"geometryType" nilIfEmpty:YES];
        if (theGeometryType) {
            placemark.geometryType = theGeometryType;
            if ([theGeometryType isEqualToString:@"point"]) {
                NSDictionary *theGeometry = [dictionary dictionaryForKey:@"geometry"];
                lat = [theGeometry floatForKey:@"lat"];
                lon = [theGeometry floatForKey:@"lon"];
                if (lat || lon) {
                    CLLocation *location = [[[CLLocation alloc] initWithLatitude:lat longitude:lon] autorelease];
                    placemark.geometry = [NSKeyedArchiver archivedDataWithRootObject:location];
                }
            } else {
                // TODO: other geometry types
            }
        }
    }
    
    return placemark;
}


@end
