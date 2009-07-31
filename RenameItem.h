#import <Cocoa/Cocoa.h>


@interface RenameItem : NSObject {
	NSString *filePath;
	NSString *newName;
	NSString *oldName;
	NSColor *textColor;
	NSImage *icon;
}
+ (id)renameItemWithPath:(NSString *)path;

- (NSString *)filePath;
- (void)setFilePath:(NSString *)path;
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
