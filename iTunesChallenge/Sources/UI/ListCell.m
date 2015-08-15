//
//  ListCell.m
//  iTunes Challenge
//
//  Created by Gregory Combs on 11/3/14.
//

#import "ListCell.h"
#import "ListDataItem.h"
#import "UtilTypeChecking.h"
#import "ImageDataSource.h"

@interface ListCell ()

@property (nonatomic,strong) ListDataItem *dataObject;
@property (nonatomic,strong) UILabel *nameLabel;
@property (nonatomic,strong) UIImageView *iconImageView;

@end


@implementation ListCell

+ (NSString *)defaultReuseIdentifier
{
    return NSStringFromClass([self class]);
}

+ (CGFloat)defaultRowHeight
{
    return 60;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        [self configure];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self configure];
    }
    return self;
}

- (void)configure
{
    CGRect bounds = self.bounds;
    CGRect imageRect = CGRectZero;
    CGRect labelRect = CGRectZero;
    CGRectDivide(bounds, &imageRect, &labelRect, 60, CGRectMinXEdge);

    labelRect = CGRectInset(labelRect, 8, 4);
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:labelRect];
    nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    nameLabel.numberOfLines = 2;
    nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    nameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    nameLabel.textColor = [UIColor colorWithWhite:114.f/255.f alpha:1];
    [self.contentView addSubview:nameLabel];
    _nameLabel = nameLabel;

    UIImageView *iconImageView = [[UIImageView alloc] initWithFrame:imageRect];
    iconImageView.translatesAutoresizingMaskIntoConstraints = NO;
    iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:iconImageView];
    _iconImageView = iconImageView;


    NSDictionary *metrics = @{@"iconSize": @([ListCell defaultRowHeight] - 12)};
    NSDictionary *bindings = NSDictionaryOfVariableBindings(nameLabel,iconImageView);

    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[iconImageView(==iconSize@900)]-[nameLabel]-|"
                                                                             options:NSLayoutFormatAlignAllCenterY
                                                                             metrics:metrics
                                                                               views:bindings]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[iconImageView(==iconSize@900)]-|"
                                                                             options:NSLayoutFormatAlignAllLeading
                                                                             metrics:metrics
                                                                               views:bindings]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[nameLabel]-|"
                                                                             options:NSLayoutFormatAlignAllLeading
                                                                             metrics:metrics views:bindings]];
    [self.contentView setNeedsUpdateConstraints];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeFontPreference:) name:UIContentSizeCategoryDidChangeNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIContentSizeCategoryDidChangeNotification object:nil];
}

- (void)didChangeFontPreference:(NSNotification *)notification
{
    self.nameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.nameLabel.text = nil;
    self.iconImageView.image = nil;
    self.dataObject = nil;
}

+ (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath dataObject:(ListDataItem *)dataObject
{
    ListCell *cell = nil;
    @try {
        cell = [tableView dequeueReusableCellWithIdentifier:[self defaultReuseIdentifier] forIndexPath:indexPath];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception while dequeueing ListCell, don't forget to register it for reuse: %@", exception);
        cell = [[ListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[self defaultReuseIdentifier]];
    }

    if (!dataObject)
        return cell;

    cell.dataObject = dataObject;
    cell.nameLabel.text = UtilTypeNonEmptyStringOrNil(dataObject.name);
    cell.iconImageView.image = dataObject.image;
    [cell.contentView layoutIfNeeded];

    return cell;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

#pragma mark - Image Loading

- (void)loadImageIfNeeded
{
    if ([self updateImageViewIfNeeded])
        return; // nothing more is requred

    ListDataItem *initialObject = self.dataObject;
    if (!initialObject)
        return;  // nothing to do

    NSURL *imageURL = initialObject.imageURL;
    if (!imageURL)
        return;  // nothing to do

    __weak ListCell *weakSelf = self;
    [[ImageDataSource sharedInstance] loadImageWithURL:imageURL completion:^(UIImage *image, NSURL *url, NSError *error) {
        __strong ListCell *strongSelf = weakSelf;
        if (!strongSelf)
            return; // we've been deallocated

        [strongSelf updateObject:initialObject withImage:image forURL:url];

        ListDataItem *currentObject = strongSelf.dataObject;
        if (currentObject &&
            ![currentObject isEqual:initialObject])
        {
            // I guess anything is possible, right?
            [strongSelf updateObject:currentObject withImage:image forURL:url];
        }

        if (![strongSelf updateImageViewIfNeeded] ||
            error)
        {
            NSLog(@"Error occurred while loading image for URL (%@): %@", url, error);
        }
    }];
}

/**
 *  Update a data object with the provided image, but only if their imageURLs match.
 */
- (void)updateObject:(ListDataItem *)dataObject withImage:(UIImage *)image forURL:(NSURL *)imageURL
{
    if (!dataObject)
        return;
    if (dataObject.imageURL &&
        imageURL &&
        [dataObject.imageURL isEqual:imageURL] &&
        image)
    {
        // we have matching URLs and an image to save
        dataObject.image = image;
    }
}

/**
 *  Update the imageView if we have the means.
 *
 *  @return True if we successfully updated the imageView (or didn't need to), otherwise false.
 */
- (BOOL)updateImageViewIfNeeded
{
    ListDataItem *object = self.dataObject;
    if (!object ||
        !object.image ||
        ![object.image isKindOfClass:[UIImage class]])
    {
        return NO;
    }
    if ([object.image isEqual:self.iconImageView.image])
        return YES;

    self.iconImageView.image = object.image;
    [self.iconImageView setNeedsLayout];
    return YES;
}

- (void)cancelLoadingImage
{
    // We *could* cancel running tasks, but let's just let them finish and cache their resuts
}

@end
