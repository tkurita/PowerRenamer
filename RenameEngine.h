#import <Cocoa/Cocoa.h>
#import <OSAKit/OSAScript.h>
#import "RenameOptionsProtocol.h"

@interface RenameEngine : NSObject {
	NSArray *targetDicts;
	OSAScript *finderSelectionController;
}

- (BOOL)resolveTargetItemsAndReturnError:(NSError **)error;
- (BOOL)resolveNewNames:(id<RenameOptionsProtocol>)optionProvider;
- (BOOL)resolveIcons;
- (BOOL)processRenameAndReturnError:(NSError **)error;

- (NSArray *)targetDicts;
- (void)setTargetDicts:(NSArray *)array;

@end
