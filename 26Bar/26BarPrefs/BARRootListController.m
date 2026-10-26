#import <Foundation/Foundation.h>
#import "BARRootListController.h"

@implementation BARRootListController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.title = @"26Bar";
	self.tableView.backgroundColor = [UIColor systemGroupedBackgroundColor];
	self.tableView.separatorInset = UIEdgeInsetsMake(0, 56, 0, 16);
	self.tableView.rowHeight = UITableViewAutomaticDimension;
	self.tableView.estimatedRowHeight = 56.0;
	self.tableView.sectionHeaderHeight = UITableViewAutomaticDimension;
	self.tableView.estimatedSectionHeaderHeight = 28.0;
	self.tableView.sectionFooterHeight = UITableViewAutomaticDimension;
	self.tableView.estimatedSectionFooterHeight = 36.0;

	UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), 132.0)];
	header.backgroundColor = [UIColor systemGroupedBackgroundColor];
	UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon@3x.png"]];
	icon.translatesAutoresizingMaskIntoConstraints = NO;
	icon.layer.cornerRadius = 15.0;
	icon.layer.masksToBounds = YES;
	UILabel *title = [UILabel new];
	title.translatesAutoresizingMaskIntoConstraints = NO;
	title.text = @"26Bar";
	title.font = [UIFont systemFontOfSize:28.0 weight:UIFontWeightBold];
	UILabel *subtitle = [UILabel new];
	subtitle.translatesAutoresizingMaskIntoConstraints = NO;
	subtitle.text = @"A modern status bar for classic iPhones.";
	subtitle.textColor = [UIColor secondaryLabelColor];
	subtitle.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];

	[header addSubview:icon];
	[header addSubview:title];
	[header addSubview:subtitle];
	[NSLayoutConstraint activateConstraints:@[
		[icon.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:20.0],
		[icon.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
		[icon.widthAnchor constraintEqualToConstant:60.0],
		[icon.heightAnchor constraintEqualToConstant:60.0],
		[title.leadingAnchor constraintEqualToAnchor:icon.trailingAnchor constant:16.0],
		[title.trailingAnchor constraintLessThanOrEqualToAnchor:header.trailingAnchor constant:-16.0],
		[title.topAnchor constraintEqualToAnchor:icon.topAnchor constant:3.0],
		[subtitle.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
		[subtitle.trailingAnchor constraintLessThanOrEqualToAnchor:header.trailingAnchor constant:-16.0],
		[subtitle.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:4.0]
	]];
	self.tableView.tableHeaderView = header;
}

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	return _specifiers;
}

@end
