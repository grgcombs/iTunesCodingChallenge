//
//  ImageDataSource.m
//  iTunes Challenge
//
//  Created by Gregory Combs on 11/4/14.
//

#import "ImageDataSource.h"

NSUInteger const ImageDataSourceCacheMemoryCapacity = (8 * 1024 * 1024);
NSUInteger const ImageDataSourceCacheDiskCapacity = (30 * 1024 * 1024);

@interface ImageDataSource ()

@property (nonatomic,strong) NSMutableDictionary *loadingTasksByURL;
@property (nonatomic,strong) NSMutableDictionary *completionBlocksByURL;
@property (nonatomic,strong) NSURLCache *imageCache;
@property (nonatomic,strong) NSURLSessionConfiguration *sessionConfig;

@end

@implementation ImageDataSource

+ (instancetype)sharedInstance
{
    static dispatch_once_t pred;
    static ImageDataSource *object = nil;
    dispatch_once(&pred, ^{ object = [[self alloc] init]; });
    return object;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _loadingTasksByURL = [@{} mutableCopy];
        _completionBlocksByURL = [@{} mutableCopy];

        _imageCache = [[NSURLCache alloc] initWithMemoryCapacity:ImageDataSourceCacheMemoryCapacity
                                                   diskCapacity:ImageDataSourceCacheDiskCapacity
                                                       diskPath:@"ImageDataCache"];

        _sessionConfig = [[NSURLSessionConfiguration defaultSessionConfiguration] copy];
        _sessionConfig.HTTPShouldUsePipelining = YES;
        _sessionConfig.requestCachePolicy = NSURLRequestReturnCacheDataElseLoad;
        _sessionConfig.URLCache = _imageCache;

    }
    return self;
}

- (void)loadImageWithURL:(NSURL *)imageURL completion:(ImageDataSourceLoadCompletionBlock)completion
{
    if (!completion ||
        !imageURL)
    {
        return;
    }
    NSURLSessionDataTask *task = self.loadingTasksByURL[imageURL];
    if (task)
    {
        switch (task.state) {
            case NSURLSessionTaskStateCompleted:
            case NSURLSessionTaskStateSuspended:
            {
                [self addCompletionBlock:completion forURL:imageURL];
                [task resume];
                break;
            }
            case NSURLSessionTaskStateRunning:
                [self addCompletionBlock:completion forURL:imageURL];
                break;
            case NSURLSessionTaskStateCanceling:
                break;
        }
        return;
    }

    [self addCompletionBlock:completion forURL:imageURL];
    task = [self taskForImageURL:imageURL];
    self.loadingTasksByURL[imageURL] = task;
    [task resume];
}

- (void)addCompletionBlock:(ImageDataSourceLoadCompletionBlock)completionBlock forURL:(NSURL *)imageURL
{
    if (!completionBlock ||
        !imageURL)
    {
        return;
    }

    NSMutableArray *blocks = self.completionBlocksByURL[imageURL];
    if (blocks)
    {
        [blocks addObject:completionBlock];
    }
    else
    {
        self.completionBlocksByURL[imageURL] = [[NSMutableArray alloc] initWithObjects:completionBlock, nil];
    }
}

- (void)executeCompletionBlocksForURL:(NSURL *)imageURL image:(UIImage *)image error:(NSError *)error
{
    if (!imageURL)
    {
        return;
    }

    NSMutableArray *blocks = self.completionBlocksByURL[imageURL];
    while (blocks.count)
    {
        ImageDataSourceLoadCompletionBlock block = blocks[0];
        @try {
            block(image, imageURL, error);
        }
        @catch (NSException *exception) {
            NSLog(@"An exception occurred while triggering completion block (url = %@): %@", imageURL, exception);
        }
        [blocks removeObjectAtIndex:0];
    }
}

- (NSURLSessionDataTask *)taskForImageURL:(NSURL *)imageURL
{
    if (!imageURL)
    {
        return nil;
    }

    __weak ImageDataSource *weakSelf = self;

    NSURLSession *session = [NSURLSession sessionWithConfiguration:self.sessionConfig];

    NSURLSessionDataTask *task = [session dataTaskWithURL:imageURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        __strong ImageDataSource *strongSelf = weakSelf;

        if (!strongSelf)
            return; // must've been deallocated, time to bail.

        UIImage *image = nil;

        if (data &&
            data.length &&
            !error)
        {
            @try {
                image = [UIImage imageWithData:data];
            }
            @catch (NSException *exception) {
                NSLog(@"Exception occurred while creating image from data (url = %@): %@", imageURL, exception);
            }
        }

        [strongSelf didFinishLoadingURL:imageURL image:image error:error];
    }];

    task.priority = NSURLSessionTaskPriorityDefault;
    return task;
}

- (void)didFinishLoadingURL:(NSURL *)imageURL image:(UIImage *)image error:(NSError *)error
{
    __weak ImageDataSource *weakSelf = self;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        __strong ImageDataSource *strongSelf = weakSelf;

        [strongSelf executeCompletionBlocksForURL:imageURL image:image error:error];

        [strongSelf pruneTaskIfPossibleForURL:imageURL];
    }];
}

- (void)pruneTaskIfPossibleForURL:(NSURL *)imageURL
{
    NSURLSessionDataTask *task = self.loadingTasksByURL[imageURL];
    if (!task)
        return;
    if (task.state != NSURLSessionTaskStateCompleted)
        return;

    [self.loadingTasksByURL removeObjectForKey:imageURL];
}

@end
