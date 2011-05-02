//
//  AddressBookUtils.m
//

#import "AddressBookUtils.h"

#pragma mark Private methods

@interface AddressBookUtils (Private)

+ (void)addNonNilValueForPropertyID:(ABPropertyID)propertyID 
                           inRecord:(ABRecordRef)record
                       toDictionary:(NSMutableDictionary *)dict
                            withKey:(NSString *)key;

@end

@implementation AddressBookUtils (Private)

+ (void)addNonNilValueForPropertyID:(ABPropertyID)propertyID 
                           inRecord:(ABRecordRef)record
                       toDictionary:(NSMutableDictionary *)dict 
                            withKey:(NSString *)key
{
    id value = nil;
    if ((propertyID == kABPersonEmailProperty) ||
        (propertyID == kABPersonPhoneProperty)) {
        value = 
        [[self class] getMultiValueRecordProperty:propertyID
                                           record:record]; 
    }
    else if ((propertyID == kABPersonBirthdayProperty) ||
             (propertyID == kABPersonCreationDateProperty) ||
             (propertyID == kABPersonModificationDateProperty)) {
        value = [[self class] dateFromRecord:record propertyID:propertyID];
    }
    else {
        value = [[self class] stringFromRecord:record propertyID:propertyID];
    }
    if (value) {
        [dict setObject:value forKey:key];
    }
}

@end


@implementation AddressBookUtils

+ (NSString *)stringFromRecord:(ABRecordRef)record 
                    propertyID:(ABPropertyID)propertyID {
    
    NSString* refString = 
    (NSString *)ABRecordCopyValue(record, propertyID);
    NSString *value = refString;
    [refString release];
    return value;
}

+ (NSDate *)dateFromRecord:(ABRecordRef)record 
                    propertyID:(ABPropertyID)propertyID {
    
    NSDate* refDate = 
    (NSDate *)ABRecordCopyValue(record, propertyID);
    NSDate *value = refDate;
    [refDate release];
    return value;
}

+ (void)setSimpleValue:(id)value
             forRecord:(ABRecordRef)record 
            propertyID:(ABPropertyID)propertyID {        
    CFErrorRef error = NULL;
    if (!ABRecordSetValue(record, propertyID, value, &error)) {
        NSLog(@"error setting value %@", [value description]);
    }
}

+ (NSArray *)getMultiValueRecordProperty:(ABPropertyID)property 
                                  record:(ABRecordRef)record {    
    NSMutableArray *result = nil;
    
    ABMultiValueRef multi = ABRecordCopyValue(record, property);
    if (multi) {
        CFIndex count = ABMultiValueGetCount(multi);
        result = [NSMutableArray arrayWithCapacity:count];
        
        for (CFIndex i = 0; i < count; i++) {
            NSDictionary *valueSet = nil;
            
            CFStringRef label = ABMultiValueCopyLabelAtIndex(multi, i);
            CFTypeRef value = ABMultiValueCopyValueAtIndex(multi, i);
            
            if (label) {
                valueSet = [NSDictionary dictionaryWithObjectsAndKeys:
                            (NSString *)label, @"label", (id)value, @"value", nil];
            } else if (value) {
                valueSet = [NSDictionary dictionaryWithObjectsAndKeys:
                            (id)value, @"value", nil];
            }
            
            if (valueSet) {
                [result addObject:valueSet];
            }
            
            if (label) {
                CFRelease(label);
            }
            if (value) {
                CFRelease(value);
            }
        }
        CFRelease(multi);
    }
    
    return result;
}

+ (void)setMultiValue:(NSArray *)valueArray 
               record:(ABRecordRef)record
           propertyID:(ABPropertyID)propertyID {

    ABMutableMultiValueRef multi = 
    ABMultiValueCreateMutable(kABMultiStringPropertyType);
    
    for (id value in valueArray) {
        if ([value isKindOfClass:[NSDictionary class]]) {
            NSString *label = [value objectForKey:@"label"];
            //label = (NSString *)kABOtherLabel;
            id simpleValue = [value objectForKey:@"value"];
            ABMultiValueAddValueAndLabel(multi, (CFTypeRef)simpleValue, 
                                         (CFStringRef)label, NULL);
        }
    }
    
    CFErrorRef error = NULL;
    if (!ABRecordSetValue(record, propertyID, multi, &error)) {
        NSLog(@"error setting values %@", [valueArray description]);
    }
    CFRelease(multi);
}

+ (NSDictionary *)dictionaryForRecord:(ABRecordRef)record {

    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:17];
    
    [[self class] 
     addNonNilValueForPropertyID:kABPersonFirstNameProperty
     inRecord:record toDictionary:dict withKey:@"kABPersonFirstNameProperty"];
    [[self class] 
     addNonNilValueForPropertyID:kABPersonLastNameProperty
     inRecord:record toDictionary:dict withKey:@"kABPersonLastNameProperty"];
    [[self class] 
     addNonNilValueForPropertyID:kABPersonMiddleNameProperty
     inRecord:record toDictionary:dict withKey:@"kABPersonMiddleNameProperty"];
    [[self class] 
     addNonNilValueForPropertyID:kABPersonPrefixProperty
     inRecord:record toDictionary:dict withKey:@"kABPersonPrefixProperty"];
    [[self class] 
     addNonNilValueForPropertyID:kABPersonSuffixProperty
     inRecord:record toDictionary:dict withKey:@"kABPersonSuffixProperty"];
    [[self class] 
     addNonNilValueForPropertyID:kABPersonNicknameProperty
     inRecord:record toDictionary:dict withKey:@"kABPersonNicknameProperty"];
    [[self class] 
     addNonNilValueForPropertyID:kABPersonFirstNamePhoneticProperty
     inRecord:record toDictionary:dict withKey:@"kABPersonFirstNamePhoneticProperty"];
    [[self class] 
     addNonNilValueForPropertyID:kABPersonLastNamePhoneticProperty
     inRecord:record toDictionary:dict withKey:@"kABPersonLastNamePhoneticProperty"];
    [[self class] 
     addNonNilValueForPropertyID:kABPersonLastNamePhoneticProperty
     inRecord:record toDictionary:dict withKey:@"kABPersonLastNamePhoneticProperty"];
    [[self class] 
     addNonNilValueForPropertyID:kABPersonOrganizationProperty
     inRecord:record toDictionary:dict withKey:@"kABPersonOrganizationProperty"];
    [[self class] 
     addNonNilValueForPropertyID:kABPersonJobTitleProperty
     inRecord:record toDictionary:dict withKey:@"kABPersonJobTitleProperty"];
    [[self class] 
     addNonNilValueForPropertyID:kABPersonJobTitleProperty
     inRecord:record toDictionary:dict withKey:@"kABPersonJobTitleProperty"];
    [[self class] 
     addNonNilValueForPropertyID:kABPersonEmailProperty
     inRecord:record toDictionary:dict withKey:@"kABPersonEmailProperty"];
    [[self class] 
     addNonNilValueForPropertyID:kABPersonPhoneProperty
     inRecord:record toDictionary:dict withKey:@"kABPersonPhoneProperty"];
    [[self class] 
     addNonNilValueForPropertyID:kABPersonBirthdayProperty
     inRecord:record toDictionary:dict withKey:@"kABPersonBirthdayProperty"];
    [[self class] 
     addNonNilValueForPropertyID:kABPersonNoteProperty
     inRecord:record toDictionary:dict withKey:@"kABPersonNoteProperty"];
    [[self class] 
     addNonNilValueForPropertyID:kABPersonFirstNameProperty
     inRecord:record toDictionary:dict withKey:@"kABPersonFirstNameProperty"];
    [[self class] 
     addNonNilValueForPropertyID:kABPersonCreationDateProperty
     inRecord:record toDictionary:dict withKey:@"kABPersonCreationDateProperty"];
    [[self class] 
     addNonNilValueForPropertyID:kABPersonModificationDateProperty
     inRecord:record toDictionary:dict withKey:@"kABPersonModificationDateProperty"];
    
    return dict;
}

+ (void)setUpABRecord:(ABRecordRef)record withDict:(NSDictionary *)dict {
    
    [[self class] 
     setSimpleValue:[dict objectForKey:@"kABPersonFirstNameProperty"]
     forRecord:record propertyID:kABPersonFirstNameProperty];

    [[self class] 
     setSimpleValue:[dict objectForKey:@"kABPersonLastNameProperty"]
     forRecord:record propertyID:kABPersonLastNameProperty];
    
    [[self class] 
     setSimpleValue:[dict objectForKey:@"kABPersonMiddleNameProperty"]
     forRecord:record propertyID:kABPersonMiddleNameProperty];
    
    [[self class] 
     setSimpleValue:[dict objectForKey:@"kABPersonPrefixProperty"]
     forRecord:record propertyID:kABPersonPrefixProperty];
    
    [[self class] 
     setSimpleValue:[dict objectForKey:@"kABPersonSuffixProperty"]
     forRecord:record propertyID:kABPersonSuffixProperty];
    
    [[self class] 
     setSimpleValue:[dict objectForKey:@"kABPersonNicknameProperty"]
     forRecord:record propertyID:kABPersonNicknameProperty];
    
    [[self class] 
     setSimpleValue:[dict objectForKey:@"kABPersonFirstNamePhoneticProperty"]
     forRecord:record propertyID:kABPersonFirstNamePhoneticProperty];
    
    [[self class] 
     setSimpleValue:[dict objectForKey:@"kABPersonLastNamePhoneticProperty"]
     forRecord:record propertyID:kABPersonLastNamePhoneticProperty];
    
    [[self class] 
     setSimpleValue:[dict objectForKey:@"kABPersonLastNamePhoneticProperty"]
     forRecord:record propertyID:kABPersonLastNamePhoneticProperty];
    
    [[self class] 
     setSimpleValue:[dict objectForKey:@"kABPersonOrganizationProperty"]
     forRecord:record propertyID:kABPersonOrganizationProperty];
    
    [[self class] 
     setSimpleValue:[dict objectForKey:@"kABPersonJobTitleProperty"]
     forRecord:record propertyID:kABPersonJobTitleProperty];
    
    [[self class] 
     setMultiValue:[dict objectForKey:@"kABPersonEmailProperty"]
     record:record propertyID:kABPersonEmailProperty];
    [[self class] 
     setMultiValue:[dict objectForKey:@"kABPersonPhoneProperty"]
     record:record propertyID:kABPersonPhoneProperty];
    
    [[self class] 
     setSimpleValue:[dict objectForKey:@"kABPersonBirthdayProperty"]
     forRecord:record propertyID:kABPersonBirthdayProperty];
    
    [[self class] 
     setSimpleValue:[dict objectForKey:@"kABPersonNoteProperty"]
     forRecord:record propertyID:kABPersonNoteProperty];
    
    [[self class] 
     setSimpleValue:[dict objectForKey:@"kABPersonFirstNameProperty"]
     forRecord:record propertyID:kABPersonFirstNameProperty];
    
    [[self class] 
     setSimpleValue:[dict objectForKey:@"kABPersonCreationDateProperty"]
     forRecord:record propertyID:kABPersonCreationDateProperty];
    
    [[self class] 
     setSimpleValue:[dict objectForKey:@"kABPersonModificationDateProperty"]
     forRecord:record propertyID:kABPersonModificationDateProperty];
}

@end
