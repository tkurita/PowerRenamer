#import <Cocoa/Cocoa.h>
#import <OSAKit/OSAScript.h>
#import "RenameOptionsProtocol.h"

@interface RenameEngine : NSObject {
	CFStringNormalizationForm normalizationForm;
}

#pragma mark public
- (BOOL)resolveTargetItemsWithSorting:(BOOL)sortFlag error:(NSError **)error;
- (BOOL)resolveNewNames:(id<RenameOptionsProtocol>)optionProvider error:(NSError **)error;
- (BOOL)narrowDownTargetItems:(id<RenameOptionsProtocol>)optionProvider error:(NSError **)error;
- (BOOL)resolveIcons;
- (BOOL)processRenameAndReturnError:(NSError **)error;
- (BOOL)applyNewNamesAndReturnError:(NSError **)error;
- (void)setTargetFiles:(NSArray *)filenames;
- (BOOL)selectInFinderReturningError:(NSError **)error;
- (void)clearTargets;
- (void)clearNewNames;

#pragma mark accessors
@property (strong) NSArray *renamedItems;
@property (nonatomic, strong) NSArray *targetDicts;
@property BOOL hasNewNames;
@property BOOL isSorted;
@property (strong) OSAScript *finderSelectionController;
@end
