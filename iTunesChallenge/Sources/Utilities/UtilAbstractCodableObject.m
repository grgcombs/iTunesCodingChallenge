//
//  UtilAbstractCodableObject.m
//  iTunes Challenge
//
//  Created by Gregory Combs on 11/4/14.
//

#import "UtilAbstractCodableObject.h"
#import "UtilTypeChecking.h"

/**
 *  This class is partially based on one that I've written previously.  This variant is
 *  simplified to some extent, for improved readability and applicability.
 */

@implementation UtilAbstractCodableObject

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self)
    {
        [self setDictionaryRepresentation:dictionary];
    }
    return self;
}

- (instancetype)init
{
    self = [self initWithDictionary:nil];
    return self;
}

#pragma mark - Coding and Copying

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    self = [self initWithDictionary:nil];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] init];
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}

+ (NSDictionary *)codableKeysAndClasses
{
    return nil;
}

#pragma mark - Dictionary Representation

- (void)setDictionaryRepresentation:(NSDictionary *)dictionaryRepresentation
{
    if (!UtilTypeDictionaryOrNil(dictionaryRepresentation))
        return;
    BOOL secureSupported = [[self class] supportsSecureCoding];
    NSDictionary *codableProperties = [[self class] codableKeysAndClasses];
    __weak UtilAbstractCodableObject *weakSelf = self;
    [dictionaryRepresentation enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        __strong UtilAbstractCodableObject *strongSelf = weakSelf;

        Class propertyClass = codableProperties[key];
        if (!propertyClass)
            return; // ignoring unknown property keys from the dictionary

        if (secureSupported && ![obj isKindOfClass:propertyClass])
        {
            NSLog(@"Expected '%@' to be a %@, but was actually a %@", key, propertyClass, [obj class]);
            return;
        }
        [strongSelf setValue:obj forKey:key];
    }];
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    __weak UtilAbstractCodableObject *weakSelf = self;
    [[[self class] codableKeysAndClasses] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        __strong UtilAbstractCodableObject *strongSelf = weakSelf;

        id value = [strongSelf valueForKey:key];
        if (value)
        {
            dict[key] = value;
        }
    }];
    return dict;
}

#pragma mark - Keyed Subscripting

- (id)objectForKeyedSubscript:(id)key
{
    if (!UtilTypeNonEmptyStringOrNil(key))
        return nil;

    if (![[self class] codableKeysAndClasses][key])
        return nil;

    return [self valueForKey:key];
}

- (void)setObject:(id)object forKeyedSubscript:(NSString *)key
{
    if (!UtilTypeNonEmptyStringOrNil(key))
        return;
    BOOL secureSupported = [[self class] supportsSecureCoding];
    NSDictionary *codableProperties = [[self class] codableKeysAndClasses];
    Class valueClass = codableProperties[key];
    if (!valueClass)
        return;
    if (secureSupported && object && ![object isKindOfClass:valueClass])
    {
        NSLog(@"Expected '%@' to be a %@, but was actually a %@", key, valueClass, [object class]);
        return;
    }
    [self setValue:object forKey:key];
}

#pragma mark - Equality, hash, and description

- (BOOL)isEqual:(id)obj
{
    if (!obj || ![obj isKindOfClass:[self class]])
        return NO;
    return [[self dictionaryRepresentation] isEqualToDictionary:[obj dictionaryRepresentation]];
}

- (NSUInteger)hash
{
    __block NSUInteger current = 31;
    __block NSUInteger hashIndex = 1;

    __weak UtilAbstractCodableObject *weakSelf = self;
    [[[self class] codableKeysAndClasses] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        __strong UtilAbstractCodableObject *strongSelf = weakSelf;

        current = [UtilAbstractCodableObject valueHashForHash:[[strongSelf valueForKey:key] hash] index:hashIndex] ^ current;
        hashIndex++;

    }];

    return current;
}

- (NSString *)description
{
    NSMutableString *description = [[NSMutableString alloc] initWithFormat:@"[%@] - ", NSStringFromClass(self.class)];

    __weak UtilAbstractCodableObject *weakSelf = self;
    [[self dictionaryRepresentation] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        __strong UtilAbstractCodableObject *strongSelf = weakSelf;

        id value = nil;
        @try {
            value = [strongSelf valueForKey:key];
        }
        @catch (NSException *exception) {
        }
        if (!value)
        {
            value = @"<nil>";
        }
        [description appendFormat:@"  %@: %@\n", key, value];
    }];
    
    return description;
}

#define NSUINT_BIT (CHAR_BIT * sizeof(NSUInteger))
#define NSUINTROTATE(val, howmuch) ((((NSUInteger)val) << howmuch) | (((NSUInteger)val) >> (NSUINT_BIT - howmuch)))

+ (NSUInteger)valueHashForHash:(NSUInteger)hash index:(NSUInteger) hashIndex
{
    if (hash == 0)
    {
        // accounts for nil objects
        hash = 31;
    }
    return NSUINTROTATE(hash, NSUINT_BIT / (hashIndex + 1));
}

@end
