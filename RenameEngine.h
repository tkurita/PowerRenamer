#import <Cocoa/Cocoa.h>


@interface RenameEngine : NSObject {
	NSArray *targetItems;
	NSArray *newNames;
	NSArray *oldNames; 
	NSMutableArray *icons;
}

- (BOOL)resolveTargetItemsAndReturnError:(NSError **)error;
- (BOOL)resolveNewNames;
- (BOOL)processRename;

- (NSArray *)targetItems;
- (void)setTargetItems:(NSArray *)array;
- (NSArray *)newNames;
- (void)setNewNames:(NSArray *)array;
- (NSArray *)oldNames;
- (void)setOldNames:(NSArray *)array;
- (NSArray *)icons;
- (void)setIcons:(NSArray *)array;

@end
