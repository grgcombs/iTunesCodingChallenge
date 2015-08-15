//
//  ListCell.h
//  iTunes Challenge
//
//  Created by Gregory Combs on 11/3/14.
//

@import UIKit;

@class ListDataItem;

@interface ListCell : UITableViewCell

+ (NSString *)defaultReuseIdentifier;

+ (CGFloat)defaultRowHeight;

+ (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
                    dataObject:(ListDataItem *)dataObject;

- (void)loadImageIfNeeded;
- (void)cancelLoadingImage;

@end
