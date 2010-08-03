// Because PersonDetails is generated and regenerated by the Core Data model, we'll keep its methods here.

#import <Foundation/Foundation.h>
#import "PersonDetails.h"

#define kPersonDetailsValueSeparatorToken @"%/%"

@interface PersonDetails (Methods)

// "Actual" value as in not a PersonDetail object, but rather the value it contains if in fact
// a PersonDetail object is stored with the given key.
- (id)actualValueForKey:(NSString *)key;
- (NSString *)formattedValueForKey:(NSString *)key;
- (NSString *)displayNameForKey:(NSString *)key;
+ (PersonDetails *)retrieveOrCreate:(NSDictionary *)selectedResult;
+ (NSString *)trimUID:(NSString *)theUID;
+ (NSArray *)realValuesFromPersonDetailsJSONDict:(NSDictionary *)jsonDict forKey:(NSString *)key;
+ (NSString *)joinedValueFromPersonDetailsJSONDict:(NSDictionary *)jsonDict forKey:(NSString *)key;

@end
