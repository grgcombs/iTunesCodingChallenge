//
//  ListDataSource.h
//  iTunes Challenge
//
//  Created by Gregory Combs on 11/3/14.
//

@import UIKit;

extern NSString * const ListDataSourceDidLoadNotificationKey;
typedef void(^ListDataSourceLoadCompletionBlock)(NSUInteger totalItems, NSError *error);

@interface ListDataSource : NSObject <UITableViewDataSource>

- (instancetype)initWithLoadCompletion:(ListDataSourceLoadCompletionBlock)loadCompletion NS_DESIGNATED_INITIALIZER;
- (IBAction)reloadData:(id)sender;

@end
