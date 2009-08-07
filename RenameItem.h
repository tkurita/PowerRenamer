#import <Cocoa/Cocoa.h>


@interface RenameItem : NSObject {
	NSString *posixPath;
	NSString *hfsPath;
	NSString *newName;
	NSString *oldName;
	NSColor *textColor;
	NSImage *icon;
}
+ (id)renameItemWithPath:(NSString *)path;
+ (id)renameItemWithHFSPath:(NSString *)path;

- (NSString *)posixPath;
- (void)setPosixPath:(NSString *)path;
- (NSString *)hfsPath;
- (void)setHfsPath:(NSString *)path;

- (NSString *)newName;
- (void)setNewName:(NSString *)name;
- (NSString *)oldName;
- (void)setOldName:(NSString *)name;
- (NSColor *)textColor;
- (void)setTextColor:(NSColor *)color;
- (NSImage *)icon;
- (void)setIcon:(NSImage *)image;

- (void)nameChanged;

@end
