//
//  UtilTypeChecking.h
//  Utilities
//
//  Created by Gregory Combs on 11/4/14.
//

@import Foundation;

/**
 *  A collection of utility functions that expedite Objective-C type checking
 */

/**
 *  Determines whether the provided object reference is nil or `NSNull`.
 *
 *  @param obj The object reference to test.
 *
 *  @return A boolean value of YES if the object reference is nill/NSNull, otherwise NO.
 */
static inline BOOL UtilTypeIsNull(id obj) { return (!obj || [obj isEqual:[NSNull null]]); }

/**
 *  Checks that the type of the provided object is a number, otherwise returns nil.
 *
 *  @param obj The object reference to test.
 *
 *  @return The original object if it is a number, otherwise nil.
 */
static inline NSNumber * UtilTypeNumberOrNil(id obj) { if (!obj || ![obj isKindOfClass:[NSNumber class]]) return nil; return obj; }

/**
 *  Checks that the type of the provided object is a dictionary, otherwise returns nil.
 *
 *  @param obj The object reference to test.
 *
 *  @return The original object if it is a dictionary, otherwise nil.
 */
static inline NSDictionary * UtilTypeDictionaryOrNil(id obj) { if (!obj || ![obj isKindOfClass:[NSDictionary class]]) return nil; return obj; }

/**
 *  Checks that the type of the provided object is an array, otherwise returns nil.
 *
 *  @param obj The object reference to test.
 *
 *  @return The original object if it is an array, otherwise nil.
 */
static inline NSArray * UtilTypeArrayOrNil(id obj) { if (!obj || ![obj isKindOfClass:[NSArray class]]) return nil; return obj; }

/**
 *  Checks that the type of the provided object is an array ***and*** that the array is not empty, otherwise returns nil.
 *
 *  @param obj The object reference to test.
 *
 *  @return The original object if it is a non-empty array, otherwise nil.
 */
static inline NSArray * UtilTypeNonEmptyArrayOrNil(id obj) { if (!UtilTypeArrayOrNil(obj) || ![obj count]) return nil; return obj; }

/**
 *  Checks that the type of the provided object is a string, otherwise returns nil.
 *
 *  @param obj The object reference to test.
 *
 *  @return The original object if it is a string, otherwise nil.
 */
static inline NSString * UtilTypeStringOrNil(id obj) { if (!obj || ![obj isKindOfClass:[NSString class]]) return nil; return obj; }

/**
 *  Checks that the type of the provided object is a string ***and*** that the string is not empty, otherwise returns nil.
 *
 *  @param obj The object reference to test.
 *
 *  @return The original object if it is a non-empty string, otherwise nil.
 */
static inline NSString * UtilTypeNonEmptyStringOrNil(id obj) { if (!UtilTypeStringOrNil(obj) || ![obj length]) return nil; return obj; }

/**
 *  Checks that the type of the provided object is a date, otherwise returns nil.
 *
 *  @param obj The object reference to test.
 *
 *  @return The original object if it is a date, otherwise nil.
 */
static inline NSDate * UtilTypeDateOrNil(id obj) { if (!obj || ![obj isKindOfClass:[NSDate class]]) return nil; return obj; }


/**
 *  Checks that the type of the provided object is data, otherwise returns nil.
 *
 *  @param obj The object reference to test.
 *
 *  @return The original object if it is data, otherwise nil.
 */
static inline NSData * UtilTypeDataOrNil(id obj) { if (!obj || ![obj isKindOfClass:[NSData class]]) return nil; return obj; }

/**
 *  Checks that the type of the provided object is data ***and*** that the data is not empty, otherwise returns nil.
 *
 *  @param obj The object reference to test.
 *
 *  @return The original object if it is non-empty data, otherwise nil.
 */
static inline NSData * UtilTypeNonEmptyDataOrNil(id obj) { if (!UtilTypeDataOrNil(obj) || ![obj length]) return nil; return obj; }
