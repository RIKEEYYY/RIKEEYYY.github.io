#import <Foundation/Foundation.h>
#import "BARRootListController.h"

@implementation BARRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	return _specifiers;
}

@end
