//
//  ListDataSource.m
//  iTunes Challenge
//
//  Created by Gregory Combs on 11/3/14.
//

#import "ListDataSource.h"
#import "ListCell.h"
#import "UtilTypeChecking.h"
#import "ListDataItem.h"

typedef NS_ENUM(NSUInteger, ListDataSourceFeedType) {
    ListDataSourceUnknownFeedType = 0,
    ListDataSourceTopFreeFeedType,
    ListDataSourceTopGrossingFeedType,
};

NSString * const ListDataSourceDidLoadNotificationKey = @"ListDataSourceDidLoadNotification";
NSUInteger const ListDataSourceCacheMemoryCapacity = (4 * 1024 * 1024);
NSUInteger const ListDataSourceCacheDiskCapacity = (20 * 1024 * 1024);

@interface ListDataSource ()
@property (nonatomic,copy) ListDataSourceLoadCompletionBlock loadCompletionBlock;
@property (nonatomic,strong) NSError *loadingError;
@property (nonatomic,assign) NSUInteger totalItemCount;
@property (nonatomic,copy) NSArray *sections;
@property (nonatomic,copy) NSOrderedSet *topFreeFeedRows;
@property (nonatomic,copy) NSOrderedSet *topGrossingFeedRows;
@property (nonatomic,strong) NSURLSessionDataTask *topFreeTask;
@property (nonatomic,strong) NSURLSessionDataTask *topGrossingTask;
@property (nonatomic,strong) NSURLCache *dataCache;
@property (nonatomic,strong) NSURLSessionConfiguration *sessionConfig;
@end

@implementation ListDataSource

- (instancetype)init
{
    self = [self initWithLoadCompletion:nil];
    return self;
}

- (instancetype)initWithLoadCompletion:(ListDataSourceLoadCompletionBlock)loadCompletion
{
    self = [super init];
    if (self)
    {
        _loadCompletionBlock = loadCompletion;

        _dataCache = [[NSURLCache alloc] initWithMemoryCapacity:ListDataSourceCacheMemoryCapacity
                                                   diskCapacity:ListDataSourceCacheDiskCapacity
                                                       diskPath:@"ListDataCache"];

        _sessionConfig = [[NSURLSessionConfiguration defaultSessionConfiguration] copy];
        _sessionConfig.HTTPShouldUsePipelining = YES;
        _sessionConfig.timeoutIntervalForRequest = 20;
        _sessionConfig.timeoutIntervalForResource = 20;
        _sessionConfig.requestCachePolicy = NSURLRequestReturnCacheDataElseLoad;
        _sessionConfig.URLCache = _dataCache;

        _sections = @[];

        [self reloadData:nil];
    }
    return self;
}

- (void)dealloc
{
    if (_topFreeTask)
    {
        [_topFreeTask cancel];
        _topFreeTask = nil;
    }
    if (_topGrossingTask)
    {
        [_topGrossingTask cancel];
        _topGrossingTask = nil;
    }
}

#pragma mark - Data Accessors

- (NSUInteger)numberOfDataSections
{
    return self.sections.count;
}

- (NSDictionary *)dataSectionForSectionIndex:(NSUInteger)sectionIndex
{
    if (!self.sections ||
        sectionIndex >= self.sections.count)
    {
        return nil;
    }
    return UtilTypeDictionaryOrNil(self.sections[sectionIndex]);
}

- (NSArray *)dataRowsForSectionIndex:(NSUInteger)sectionIndex
{
    NSDictionary *section = [self dataSectionForSectionIndex:sectionIndex];
    if (!section)
    {
        return nil;
    }
    return UtilTypeArrayOrNil(section[@"rows"]);
}

- (ListDataItem *)dataObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSArray *rows = [self dataRowsForSectionIndex:indexPath.section];
    if (!rows ||
        indexPath.row >= rows.count)
    {
        return nil;
    }
    ListDataItem *dataObject = rows[indexPath.row];
    if (!dataObject || ![dataObject isKindOfClass:[ListDataItem class]])
        return nil;
    return dataObject;
}

#pragma mark - UITableViewDataSource methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ListDataItem *dataObject = [self dataObjectForIndexPath:indexPath];
    return [ListCell tableView:tableView cellForRowAtIndexPath:indexPath dataObject:dataObject];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self numberOfDataSections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self dataRowsForSectionIndex:section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSDictionary *dataSection = [self dataSectionForSectionIndex:section];
    if (!dataSection)
        return nil;
    return UtilTypeStringOrNil(dataSection[@"name"]);
}

#pragma mark - Data Acquisition

- (void)reloadData:(id)sender
{
    self.totalItemCount = 0;
    self.loadingError = nil;
    self.topFreeFeedRows = nil;
    self.topGrossingFeedRows = nil;

    __weak ListDataSource *weakSelf = self;

    NSURL *topFreeURL = [NSURL URLWithString:@"http://itunes.apple.com/us/rss/topfreeapplications/limit=200/json"];
    self.topFreeTask = [self taskForFeedDictionaryWithURL:topFreeURL completion:^(NSDictionary *feedDictionary, NSError *error) {
        __strong ListDataSource *strongSelf = weakSelf;
        if (!strongSelf)
            return; // must've been deallocated, time to bail.

        if (error)
        {
            NSLog(@"Caught an error fetching top free apps, expect problems: %@", error);
            strongSelf.loadingError = error;
        }

        NSOrderedSet *freeRowsSet = nil;
        if (UtilTypeDictionaryOrNil(feedDictionary))
        {
            NSArray *freeRows = UtilTypeNonEmptyArrayOrNil(feedDictionary[@"feed"][@"entry"]);
            freeRowsSet = [NSOrderedSet orderedSetWithArray:freeRows];
        }

        if (!freeRowsSet)
        {
            freeRowsSet = [NSOrderedSet orderedSet];
        }
        [strongSelf saveFeedRows:freeRowsSet feedType:ListDataSourceTopFreeFeedType];
    }];
    [self.topFreeTask resume];

    NSURL *topGrossingURL = [NSURL URLWithString:@"http://itunes.apple.com/us/rss/topgrossingapplications/limit=200/json"];
    _topGrossingTask = [self taskForFeedDictionaryWithURL:topGrossingURL completion:^(NSDictionary *feedDictionary, NSError *error) {
        __strong ListDataSource *strongSelf = weakSelf;
        if (!strongSelf)
            return; // must've been deallocated, time to bail.

        if (error)
        {
            NSLog(@"Caught an error fetching top grossing apps, expect problems: %@", error);
            strongSelf.loadingError = error;
        }

        NSOrderedSet *grossingRowsSet = nil;
        if (UtilTypeDictionaryOrNil(feedDictionary))
        {
            NSArray *grossingRows = UtilTypeNonEmptyArrayOrNil(feedDictionary[@"feed"][@"entry"]);
            grossingRowsSet = [NSOrderedSet orderedSetWithArray:grossingRows];
        }

        if (!grossingRowsSet)
        {
            grossingRowsSet = [NSOrderedSet orderedSet];
        }
        [strongSelf saveFeedRows:grossingRowsSet feedType:ListDataSourceTopGrossingFeedType];
    }];
    [self.topGrossingTask resume];
}

- (void)notifyDidFinishLoading
{
    if (self.loadCompletionBlock)
    {
        @try {
            self.loadCompletionBlock(self.totalItemCount, self.loadingError);
        }
        @catch (NSException *exception) {
            NSLog(@"Exception while triggering loadCompletionBlock: %@", exception);
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ListDataSourceDidLoadNotificationKey object:self];
}

- (NSURLSessionDataTask *)taskForFeedDictionaryWithURL:(NSURL *)feedURL completion:(void (^)(NSDictionary *feedDictionary, NSError *error))completion
{
    if (!completion ||
        !feedURL)
    {
        return nil;
    }

    __weak ListDataSource *weakSelf = self;

    NSURLSession *session = [NSURLSession sessionWithConfiguration:self.sessionConfig];

    NSURLSessionDataTask *task = [session dataTaskWithURL:feedURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        __strong ListDataSource *strongSelf = weakSelf;

        if (!strongSelf || !completion)
            return; // must've been deallocated, time to bail.

        NSDictionary *feedCatalog = nil;
        NSError *errorToSend = error;

        if (UtilTypeNonEmptyDataOrNil(data) &&
            !error)
        {
            NSError *jsonError = nil;
            NSDictionary *parsed = UtilTypeDictionaryOrNil([NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError]);
            if (parsed)
            {
                feedCatalog = parsed;
            }
            errorToSend = jsonError;
        }

        completion(feedCatalog, errorToSend);
    }];
    task.priority = NSURLSessionTaskPriorityHigh;
    return task;
}

#pragma mark - Data Processing

- (void)saveFeedRows:(NSOrderedSet *)feedRows feedType:(ListDataSourceFeedType)feedType
{
    __weak ListDataSource *weakSelf = self;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        __strong ListDataSource *strongSelf = weakSelf;
        if (!strongSelf)
            return;
        NSString *typeString = @"free";
        if (feedType == ListDataSourceTopFreeFeedType)
            strongSelf.topFreeFeedRows = feedRows;
        else if (feedType == ListDataSourceTopGrossingFeedType)
        {
            strongSelf.topGrossingFeedRows = feedRows;
            typeString = @"grossing";
        }

        NSLog(@"Received %ld %@ app listings", feedRows.count, typeString);

        // I prefer to do more processing in the background, but for challenge expediency ...
        [strongSelf processCompletedFeedsIfReady];
    }];
}

- (void)processCompletedFeedsIfReady
{
    if (!self.topFreeFeedRows ||
        !self.topGrossingFeedRows)
    {
        // we're probably not finished downloading both feeds yet
        return;
    }

    NSOrderedSet *prunedItems = [self pruneTheGreedy:self.topGrossingFeedRows fromTheFree:self.topFreeFeedRows];
    self.totalItemCount = prunedItems.count;

    self.sections = [self categorizePrunedFeed:prunedItems];

    // We don't need these anymore, free some memory
    self.topFreeFeedRows = nil;
    self.topGrossingFeedRows = nil;

    [self notifyDidFinishLoading];
}

- (NSOrderedSet *)pruneTheGreedy:(NSOrderedSet *)greedyRows fromTheFree:(NSOrderedSet *)freeRows
{
    if (!freeRows ||
        !greedyRows)
    {
        // we're probably not finished downloading both feeds yet
        return nil;
    }

    if (!freeRows.count)
    {
        // nothing to be done -- we've got no useful data
        NSLog(@"Empty payload for top free apps feed.");
        return freeRows;
    }

    if (!greedyRows.count)
    {
        NSLog(@"Not pruning free apps due to empty payload for top grossing list");
        return freeRows;
    }

    NSMutableOrderedSet *pruningFeed = [freeRows mutableCopy];
    [pruningFeed minusOrderedSet:greedyRows];
    return pruningFeed;
}

- (NSArray *)categorizePrunedFeed:(NSOrderedSet *)feedItems
{
    NSString *unknownSectionName = NSLocalizedString(@"UnknownCategory", @"Unidentifiable application category");
    NSMutableDictionary *sections = [@{} mutableCopy];

    __weak ListDataSource *weakSelf = self;
    [feedItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        __strong ListDataSource *strongSelf = weakSelf;

        if (!UtilTypeDictionaryOrNil(obj))
        {
            // unexpected feed item structure, keep looking for something useful
            return;
        }
        NSDictionary *feedItem = obj;

        // Find the category label and use it as the section key for grouping
        NSString *sectionName = UtilTypeStringOrNil([feedItem valueForKeyPath:@"category.attributes.label"]);
        if (!sectionName)
        {
            sectionName = unknownSectionName;
        }

        NSMutableDictionary *sectionItem = sections[sectionName];
        if (!sectionItem)
        {
            // Lazily create a new empty section with our new section name
            sectionItem = [@{@"name": sectionName,
                             @"rows": [@[] mutableCopy]} mutableCopy];
            sections[sectionName] = sectionItem;
        }

        ListDataItem *dataObject = [strongSelf dataObjectForFeedItem:feedItem];
        if (dataObject)
        {
            [sectionItem[@"rows"] addObject:dataObject];
        }
    }];

    NSDictionary *unknownSection = sections[unknownSectionName];
    if (unknownSection)
    {
        // we want to stick this at the end instead of it's normal sort position
        [sections removeObjectForKey:unknownSection];
    }


    NSArray *sectionKeys = [[sections allKeys] sortedArrayUsingSelector:@selector(localizedStandardCompare:)];

    NSMutableArray *orderedSections = [@[] mutableCopy];
    [sectionKeys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [orderedSections addObject:sections[obj]];
    }];

    if (unknownSection)
    {
        [orderedSections addObject:unknownSection];
    }

    return orderedSections;
}

- (ListDataItem *)dataObjectForFeedItem:(NSDictionary *)feedItem
{
    ListDataItem *dataObject = [[ListDataItem alloc] initWithDictionary:feedItem];
    if (!dataObject || !dataObject.isValid)
        return nil;
    return dataObject;
}

@end
