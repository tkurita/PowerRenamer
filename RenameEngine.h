#import <Cocoa/Cocoa.h>
#import <OSAKit/OSAScript.h>
#import "RenameOptionsProtocol.h"

@interface RenameEngine : NSObject {
	NSArray *targetDicts;
	OSAScript *finderSelectionController;
	BOOL hasNewNames;
}

- (BOOL)resolveTargetItemsWithSorting:(BOOL)sortFlag error:(NSError **)error;
- (BOOL)resolveNewNames:(id<RenameOptionsProtocol>)optionProvider error:(NSError **)error;
- (BOOL)narrowDownTargetItems:(id<RenameOptionsProtocol>)optionProvider error:(NSError **)error;
- (BOOL)resolveIcons;
- (BOOL)processRenameAndReturnError:(NSError **)error;

- (NSArray *)targetDicts;
- (void)setTargetDicts:(NSArray *)array;

- (void)setTargetFiles:(NSArray *)filenames;
- (BOOL)hasNewNames;
- (void)clearNewNames;
- (BOOL)selectInFinderReturningError:(NSError **)error;
- (void)clearTargets;
@end
