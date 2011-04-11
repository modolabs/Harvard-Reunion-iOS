//
//  AddressBookUtils.h
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>


@interface AddressBookUtils : NSObject {

}

+ (NSString *)stringFromRecord:(ABRecordRef)record 
                    propertyID:(ABPropertyID)propertyID;

+ (NSDate *)dateFromRecord:(ABRecordRef)record 
                propertyID:(ABPropertyID)propertyID;

+ (void)setSimpleValue:(id)value
             forRecord:(ABRecordRef)record 
            propertyID:(ABPropertyID)propertyID;

+ (NSArray *)getMultiValueRecordProperty:(ABPropertyID)property 
                                  record:(ABRecordRef)record;

+ (void)setMultiValue:(NSArray *)valueArray 
               record:(ABRecordRef)record
           propertyID:(ABPropertyID)propertyID;

+ (NSDictionary *)dictionaryForRecord:(ABRecordRef)record;

+ (void)setUpABRecord:(ABRecordRef)record withDict:(NSDictionary *)dict;

@end
