#import <Cocoa/Cocoa.h>
#import "RenameOptionsProtocol.h"

@interface RenameEngine : NSObject {
	NSArray *targetDicts;
}

- (BOOL)resolveTargetItemsAndReturnError:(NSError **)error;
- (BOOL)resolveNewNames:(id<RenameOptionsProtocol>)optionProvider;
- (BOOL)resolveIcons;
- (BOOL)processRename;

- (NSArray *)targetDicts;
- (void)setTargetDicts:(NSArray *)array;

@end
