//
//  ListSectionHeaderView.m
//  iTunes Challenge
//
//  Created by Gregory Combs on 11/5/14.
//

#import "ListSectionHeaderView.h"

@implementation ListSectionHeaderView

+ (NSString *)defaultReuseIdentifier
{
    return @"ListSectionHeaderView";
}

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
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
    static UIColor *defaultColor = nil;
    if (!defaultColor)
    {
        defaultColor = [UIColor colorWithRed:151.f/255.f green:203.f/255.f blue:100.f/255.f alpha:1];
    }

    UIColor *white = [UIColor whiteColor];
    self.contentView.backgroundColor = white;
    
    self.textLabel.backgroundColor = white;
    self.textLabel.textColor = defaultColor;
    self.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    self.textLabel.opaque = YES;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeFontPreference:) name:UIContentSizeCategoryDidChangeNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIContentSizeCategoryDidChangeNotification object:nil];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.textLabel.text = nil;
}

- (void)didChangeFontPreference:(NSNotification *)notification
{
    self.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
}

@end
