
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "FacebookPost.h"

@class FacebookParentPost;

@interface FacebookComment : FacebookPost {
@private
}
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) FacebookParentPost * parent;

+ (FacebookComment *)commentWithDictionary:(NSDictionary *)dictionary;
+ (FacebookComment *)commentWithID:(NSString *)commentID;

@end
