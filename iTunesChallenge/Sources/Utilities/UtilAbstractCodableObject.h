//
//  UtilAbstractCodableObject.h
//  iTunes Challenge
//
//  Created by Gregory Combs on 11/4/14.
//

@import Foundation;

/**
 *  This class is based on various incarnations seen over the years such as from from Dave DeLong, Mike Ash, etc.
 *  This variant is simplified to some extent, for improved readability and applicability.
 */

@interface UtilAbstractCodableObject : NSObject <NSCopying, NSSecureCoding>

/**
 *  This method initializes a new object instance using the provided dictionary to populate the objects property values.
 *
 *  @param dictionaryRepresentation A dictionary with keys matching the receiver's property names.  Values should
 *                                  be of the same type as the matching property to avoid issues.
 *
 *  @return A newly initialized object instance.
 */
- (instancetype)initWithDictionary:(NSDictionary *)dictionary NS_DESIGNATED_INITIALIZER;

/**
 *  This method returns an dictionary containing the names and classes of all the properties of the receiver class that
 *  will be automatically saved, loaded and copied when instances are archived using NSKeyedArchiver/Unarchiver.
 *  Subclasses may opt to override this class method to customize the codable/copyable properties.
 *
 *  @return A dictionary of the codable/copyable property keys and classes on the receiver class.
 */
+ (NSDictionary *)codableKeysAndClasses;

/**
 *  As a getter, this method returns a dictionary of the keys and values of all the codable/copyable properties 
 *  of the receiver.
 *
 *  As a setter, this method populates the receiver's properties based on the key/value pairs found in the dictionary.
 */
@property (nonatomic,assign) NSDictionary *dictionaryRepresentation;

/**
 *  Return the receiver's value for the provided property key.
 *
 *  @param key A key string for the desired property value.
 *
 *  @return A property value corresponding to the key.
 */
- (id)objectForKeyedSubscript:(id)key;

/**
 *  Set the receiver's value for the provided property key
 *
 *  @param object The value to set.
 *  @param key    The key string for the property value to set.
 */
- (void)setObject:(id)object forKeyedSubscript:(NSString *)key;

@end
