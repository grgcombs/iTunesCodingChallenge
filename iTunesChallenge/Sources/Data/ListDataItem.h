//
//  ListDataItem.h
//  iTunes Challenge
//
//  Created by Gregory Combs on 11/4/14.
//

#import "UtilAbstractCodableObject.h"
@import UIKit;

extern const struct ListDataItemKeys {
    __unsafe_unretained NSString * name;
    __unsafe_unretained NSString * summary;
    __unsafe_unretained NSString * itemURL;
    __unsafe_unretained NSString * imageURL;
    __unsafe_unretained NSString * image;
} ListDataItemKeys;

@interface ListDataItem : UtilAbstractCodableObject

@property (nonatomic,readonly) BOOL isValid;
@property (nonatomic,copy) NSString *name;
@property (nonatomic,copy) NSString *summary;
@property (nonatomic,copy) NSURL *itemURL;
@property (nonatomic,copy) NSURL *imageURL;
@property (nonatomic,strong) UIImage *image;

@end
