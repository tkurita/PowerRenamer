#import <Cocoa/Cocoa.h>


@interface RenameEngine : NSObject {
	NSArray *targetDicts;
}

- (BOOL)resolveTargetItemsAndReturnError:(NSError **)error;
- (BOOL)resolveNewNames;
- (BOOL)resolveIcons;
- (BOOL)processRename;

- (NSArray *)targetDicts;
- (void)setTargetDicts:(NSArray *)array;

@end
