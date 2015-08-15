//
//  ListDataItemTests.m
//  iTunes Challenge
//
//  Created by Gregory Combs on 11/4/14.
//

@import UIKit;
@import XCTest;

#import "ListDataItem.h"

@interface ListDataItemTests : XCTestCase
@property (nonatomic,strong) NSDictionary *validItemDictionary;
@property (nonatomic,strong) NSDictionary *invalidItemDictionary;
@end

@implementation ListDataItemTests

- (void)testItemInstantiatesFromDictionary
{
    ListDataItem *dataItem = [[ListDataItem alloc] initWithDictionary:self.validItemDictionary];
    XCTAssertNotNil(dataItem, @"Data item should be instantiated with a valid dictionary");

    XCTAssertTrue(dataItem.isValid, @"Data item should be valid with a valid dictionary");

    XCTAssertEqualObjects(dataItem.name, @"Facebook Messenger - Facebook, Inc.", @"Data item name should equal the one provided in the dictionary");

    XCTAssertNotNil(dataItem.summary, @"Data item summary should be populated");

    XCTAssertNotNil(dataItem.itemURL, @"Data item itemURL should be populated");

    XCTAssertNotNil(dataItem.imageURL, @"Data item imageURL should be populated");
}

- (void)testItemShouldBeInvalidWithInvalidData
{
    ListDataItem *dataItem = [[ListDataItem alloc] initWithDictionary:self.invalidItemDictionary];
    XCTAssertNotNil(dataItem, @"Data item should be instantiated, though not valid");

    XCTAssertFalse(dataItem.isValid, @"Data item should be invalid with an invalid dictionary");
}

- (void)testItemShouldBeValidWithManualValidData
{
    ListDataItem *dataItem = [[ListDataItem alloc] init];
    XCTAssertNotNil(dataItem, @"Data item should be instantiated, though not yet valid");

    dataItem.name = @"Greg";
    dataItem.summary = @"Summary";
    dataItem.itemURL = [NSURL URLWithString:@"http://www.apple.com"];
    dataItem.imageURL = [NSURL URLWithString:@"http://images.apple.com/global/elements/flags/16x16/usa_2x.png"];

    XCTAssertTrue(dataItem.isValid, @"Data item should be valid with a valid manual data");
}

- (void)testItemShouldBeArchivable
{
    ListDataItem *dataItem = [[ListDataItem alloc] init];
    XCTAssertNotNil(dataItem, @"Data item should be instantiated, though not yet valid");

    dataItem.name = @"Greg";
    dataItem.summary = @"Summary";
    dataItem.itemURL = [NSURL URLWithString:@"http://www.apple.com"];
    dataItem.imageURL = [NSURL URLWithString:@"http://images.apple.com/global/elements/flags/16x16/usa_2x.png"];

    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    archiver.requiresSecureCoding = YES;
    [archiver encodeObject:dataItem forKey:@"root"];
    [archiver finishEncoding];

    XCTAssertGreaterThan(data.length, 0, @"Data item should be archivable -- valid attributes should yield non-empty data.");
}

- (void)testItemShouldBeUnarchivable
{
    ListDataItem *dataItem = [[ListDataItem alloc] initWithDictionary:self.validItemDictionary];
    XCTAssertNotNil(dataItem, @"Data item should be instantiated");

    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    archiver.requiresSecureCoding = YES;
    [archiver encodeObject:dataItem forKey:@"root"];
    [archiver finishEncoding];

    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    ListDataItem *newDataItem = [unarchiver decodeObjectOfClass:[ListDataItem class] forKey:@"root"];
    XCTAssertNotNil(newDataItem, @"New data item should be instantiated via unarchiver");
    XCTAssertTrue(newDataItem.isValid, @"New data item should be valid with a valid dictionary");
    XCTAssertEqualObjects(newDataItem.name, @"Facebook Messenger - Facebook, Inc.", @"New data item name should equal the one provided in the dictionary, as archived previously");
}

#pragma mark - Setup and Teardown

- (void)setUp
{
    [super setUp];
    self.validItemDictionary = @{
                                 @"category": @{
                                         @"attributes": @{
                                                 @"label": @"Social Networking"
                                                 }
                                         },
                                 @"im:image": @[
                                         @{
                                             @"attributes": @{
                                                     @"height": @"53"
                                                     },
                                             @"label": @"http://a959.phobos.apple.com/us/r30/Purple5/v4/54/84/1c/54841cd2-2b8d-37de-7e66-f99833f65a35/mzl.kgxgsvjo.53x53-50.png"
                                             }
                                         ],
                                 @"im:name": @{
                                         @"label": @"Facebook Messenger"
                                         },
                                 @"link": @{
                                         @"attributes": @{
                                                 @"href": @"https://itunes.apple.com/us/app/facebook-messenger/id454638411?mt=8&uo=2"
                                                 }
                                         },
                                 @"summary": @{
                                         @"label": @"Instantly reach the people in your life\u2014for free. Messenger is just like texting, but you don't have to pay for every message (it works with your data plan). \n"
                                         },
                                 @"title": @{
                                         @"label": @"Facebook Messenger - Facebook, Inc."
                                         }
                                 };

    self.invalidItemDictionary = @{
                                   @"category": @{
                                           @"attributes": @{
                                                   @"label": @"Social Networking"
                                                   }
                                           },
                                   @"im:name": @{
                                           @"label": @"Facebook Messenger"
                                           },
                                   @"summary": @{
                                           @"label": @"Instantly reach the people in your life\u2014for free. Messenger is just like texting, but you don't have to pay for every message (it works with your data plan). \n"
                                           }
                                 };

}

- (void)tearDown
{
    [super tearDown];
}

@end
