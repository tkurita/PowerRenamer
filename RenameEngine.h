#import <Cocoa/Cocoa.h>
#import <OSAKit/OSAScript.h>
#import "RenameOptionsProtocol.h"

@interface RenameEngine : NSObject {
	NSArray *targetDicts;
	OSAScript *finderSelectionController;
	BOOL hasNewNames;
	NSArray *renamedItems;
}

#pragma mark public
- (BOOL)resolveTargetItemsWithSorting:(BOOL)sortFlag error:(NSError **)error;
- (BOOL)resolveNewNames:(id<RenameOptionsProtocol>)optionProvider error:(NSError **)error;
- (BOOL)narrowDownTargetItems:(id<RenameOptionsProtocol>)optionProvider error:(NSError **)error;
- (BOOL)resolveIcons;
- (BOOL)processRenameAndReturnError:(NSError **)error;

- (void)setTargetFiles:(NSArray *)filenames;
- (BOOL)selectInFinderReturningError:(NSError **)error;
- (void)clearTargets;
- (void)clearNewNames;

#pragma mark accessors
- (NSArray *)targetDicts;
- (void)setTargetDicts:(NSArray *)array;
- (void)setRenamedItems:(NSArray *)array;
- (BOOL)hasNewNames;
@end
