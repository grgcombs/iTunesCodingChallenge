//
//  ListViewController
//  iTunes Challenge
//
//  Created by Gregory Combs on 11/3/14.
//

#import "ListViewController.h"
#import "ListCell.h"
#import "ListSectionHeaderView.h"
#import "ListDataSource.h"

@interface ListViewController ()

@property (nonatomic,strong) ListDataSource *dataSource;
@property (nonatomic,strong) UIRefreshControl *refreshControl;

@end


@implementation ListViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeFontPreference:) name:UIContentSizeCategoryDidChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIContentSizeCategoryDidChangeNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"ListTitle", @"Title for list controller");

    __weak ListViewController *weakSelf = self;
    _dataSource = [[ListDataSource alloc] initWithLoadCompletion:^(NSUInteger totalItems, NSError *error) {
        __strong ListViewController *strongSelf = weakSelf;
        if (!strongSelf)
        {
            return;
        }
        [strongSelf didFinishLoadWithItemCount:totalItems error:error];
    }];

    UIColor *backgroundColor = [UIColor colorWithWhite:0.80f alpha:1];
    self.view.backgroundColor = backgroundColor;

    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _tableView.backgroundColor = backgroundColor;
    _tableView.rowHeight = [ListCell defaultRowHeight];
    _tableView.dataSource = _dataSource;
    _tableView.delegate = self;
    [_tableView registerClass:[ListCell class] forCellReuseIdentifier:[ListCell defaultReuseIdentifier]];
    [_tableView registerClass:[ListSectionHeaderView class] forHeaderFooterViewReuseIdentifier:[ListSectionHeaderView defaultReuseIdentifier]];
    [self.view addSubview:_tableView];

    _refreshControl = [[UIRefreshControl alloc] init];
    [_refreshControl addTarget:_dataSource action:@selector(reloadData:) forControlEvents:UIControlEventValueChanged];
    [_tableView addSubview:_refreshControl];

    self.tableView.tableHeaderView = [self buildListHeader];

    [_tableView reloadData];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    ListSectionHeaderView *headerView = (ListSectionHeaderView *)[tableView dequeueReusableHeaderFooterViewWithIdentifier:[ListSectionHeaderView defaultReuseIdentifier]];
    if (!headerView)
        return nil;

    headerView.textLabel.text = [self.dataSource tableView:tableView titleForHeaderInSection:section];
    return headerView;
}

- (void)didFinishLoadWithItemCount:(NSUInteger)itemCount error:(NSError *)error
{
    if (!self.isViewLoaded ||
        !self.tableView)
    {
        return;
    }

    [self.refreshControl endRefreshing];

    [self.tableView reloadData];

    [self loadVisibleCellImagesIfNeeded];

    if (error)
    {
        NSString *title = NSLocalizedString(@"DataErrorTitle", @"Title for alert box due to data loading error");
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"An error occurred while loading data:\n %@", @"Message for alert box due to data loading error"), [error localizedDescription]];
        NSString *ok = NSLocalizedString(@"OK", nil);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:ok otherButtonTitles:nil];
        [alert show];
    }
}

- (void)didChangeFontPreference:(NSNotification *)notification
{
    if (!self.isViewLoaded)
        return;
    self.tableView.tableHeaderView = [self buildListHeader];
}

- (UIView *)buildListHeader
{
    CGRect headerRect = self.view.bounds;
    headerRect.size.height = 60;
    UIView *header = [[UIView alloc] initWithFrame:headerRect];
    header.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    UIColor *offWhite = [UIColor colorWithWhite:0.94f alpha:1];
    header.backgroundColor = offWhite;
    header.opaque = YES;

    CGRect labelRect = CGRectInset(headerRect, 10, 4);
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:labelRect];
    headerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    headerLabel.opaque = YES;
    headerLabel.numberOfLines = 2;
    headerLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    headerLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    headerLabel.textColor = [UIColor colorWithWhite:114.f/255.f alpha:1];
    headerLabel.text = NSLocalizedString(@"ListDescription", @"A description of the list controller's purpose and contents");
    headerLabel.backgroundColor = offWhite;
    [header addSubview:headerLabel];

    NSDictionary *bindings = NSDictionaryOfVariableBindings(headerLabel);

    [header addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[headerLabel]-|"
                                                                   options:NSLayoutFormatAlignAllBaseline
                                                                   metrics:nil
                                                                     views:bindings]];
    [header addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[headerLabel]-|"
                                                                   options:NSLayoutFormatAlignAllLeading
                                                                   metrics:nil
                                                                     views:bindings]];
    [header setNeedsUpdateConstraints];

    return header;
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if ([cell isKindOfClass:[ListCell class]])
    {
        [(ListCell *)cell cancelLoadingImage];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self loadVisibleCellImagesIfNeeded];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
    {
        // user forcibly stopped the scrolling
        [self loadVisibleCellImagesIfNeeded];
    }
}

- (void)loadVisibleCellImagesIfNeeded
{
    if (!self.isViewLoaded)
        return;
    for (ListCell *cell in self.tableView.visibleCells)
    {
        [(ListCell *)cell loadImageIfNeeded];
    }
}

@end
