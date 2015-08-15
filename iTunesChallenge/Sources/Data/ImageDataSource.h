//
//  ImageDataSource.h
//  iTunes Challenge
//
//  Created by Gregory Combs on 11/4/14.
//

@import UIKit;

typedef void(^ImageDataSourceLoadCompletionBlock)(UIImage *image, NSURL *url, NSError *error);

@interface ImageDataSource : NSObject

+ (instancetype)sharedInstance;

- (void)loadImageWithURL:(NSURL *)imageURL completion:(ImageDataSourceLoadCompletionBlock)completion;

@end
