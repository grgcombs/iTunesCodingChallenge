//
//  ListDataItem.m
//  iTunes Challenge
//
//  Created by Gregory Combs on 11/4/14.
//

#import "ListDataItem.h"
#import "UtilTypeChecking.h"

const struct ListDataItemKeys ListDataItemKeys = {
    .name = @"name",
    .summary = @"summary",
    .itemURL = @"itemURL",
    .imageURL = @"imageURL",
    .image = @"image"
};

@implementation ListDataItem

- (void)setDictionaryRepresentation:(NSDictionary *)dictionary
{
    if (!UtilTypeDictionaryOrNil(dictionary))
        return;

    self.name = UtilTypeNonEmptyStringOrNil([dictionary valueForKeyPath:@"title.label"]);

    self.summary = UtilTypeNonEmptyStringOrNil([dictionary valueForKeyPath:@"summary.label"]);

    NSString *appLink = UtilTypeNonEmptyStringOrNil([dictionary valueForKeyPath:@"link.attributes.href"]);
    if (appLink)
    {
        NSURL *url = [NSURL URLWithString:appLink];
        if (url)
        {
            self.itemURL = url;
        }
    }

    NSArray *iconLinks = UtilTypeNonEmptyArrayOrNil([dictionary valueForKeyPath:@"im:image"]);
    if (iconLinks)
    {
        static NSSortDescriptor *sortByHeight = nil;
        if (!sortByHeight)
        {
            // no sense in recreating this over and over again
            sortByHeight = [NSSortDescriptor sortDescriptorWithKey:@"attributes.height" ascending:YES];
        }
        NSArray *sortedIconLinks = [iconLinks sortedArrayUsingDescriptors:@[sortByHeight]];
        NSDictionary *smallestIconInfo = sortedIconLinks[0];
        NSString *iconLink = UtilTypeNonEmptyStringOrNil(smallestIconInfo[@"label"]);
        if (iconLink)
        {
            NSURL *iconUrl = [NSURL URLWithString:iconLink];
            if (iconUrl)
            {
                self.imageURL = iconUrl;
            }
        }
    }
}

- (BOOL)isValid
{
    return (UtilTypeNonEmptyStringOrNil(self.name) &&
            self.imageURL);
}

- (id)copyWithZone:(NSZone *)zone
{
    ListDataItem *copy = [super copyWithZone:zone];
    if (copy)
    {
        if (self.name)
            copy.name = [self.name copyWithZone:zone];
        if (self.summary)
            copy.summary = [self.summary copyWithZone:zone];
        if (self.itemURL)
            copy.itemURL = [self.itemURL copyWithZone:zone];
        if (self.imageURL)
            copy.imageURL = [self.imageURL copyWithZone:zone];
        copy.image = self.image;
    }
    return copy;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (!self)
    {
        return self;
    }
    NSSet *allowedString = [NSSet setWithObjects:[NSString class], [NSNull class], nil];
    NSSet *allowedURL = [NSSet setWithObjects:[NSURL class], [NSNull class], nil];
    NSSet *allowedImage = [NSSet setWithObjects:[UIImage class], [NSNull class], nil];
    @try {
        if ([decoder containsValueForKey:ListDataItemKeys.name])
            self.name = [decoder decodeObjectOfClasses:allowedString forKey:ListDataItemKeys.name];
        if ([decoder containsValueForKey:ListDataItemKeys.summary])
            self.summary = [decoder decodeObjectOfClasses:allowedString forKey:ListDataItemKeys.summary];
        if ([decoder containsValueForKey:ListDataItemKeys.itemURL])
            self.itemURL = [decoder decodeObjectOfClasses:allowedURL forKey:ListDataItemKeys.itemURL];
        if ([decoder containsValueForKey:ListDataItemKeys.imageURL])
            self.imageURL = [decoder decodeObjectOfClasses:allowedURL forKey:ListDataItemKeys.imageURL];
        if ([decoder containsValueForKey:ListDataItemKeys.image])
            self.image = [decoder decodeObjectOfClasses:allowedImage forKey:ListDataItemKeys.image];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception while decoding plist: %@", exception);
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    if (self.name)
        [encoder encodeObject:self.name forKey:ListDataItemKeys.name];
    if (self.summary)
        [encoder encodeObject:self.summary forKey:ListDataItemKeys.summary];
    if (self.itemURL)
        [encoder encodeObject:self.itemURL forKey:ListDataItemKeys.itemURL];
    if (self.imageURL)
        [encoder encodeObject:self.imageURL forKey:ListDataItemKeys.imageURL];
    if (self.image)
        [encoder encodeObject:self.image forKey:ListDataItemKeys.image];
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}

+ (NSDictionary *)codableKeysAndClasses
{
    return @{ListDataItemKeys.name: [NSString class],
             ListDataItemKeys.summary: [NSString class],
             ListDataItemKeys.itemURL: [NSURL class],
             ListDataItemKeys.imageURL: [NSURL class],
             ListDataItemKeys.image: [UIImage class]};
}

@end
