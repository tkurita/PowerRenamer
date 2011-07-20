#import <Cocoa/Cocoa.h>


@interface RenameItem : NSObject {
	NSString *posixPath;
	NSString *hfsPath;
	NSString *newName;
	NSString *oldName;
	NSColor *textColor;
	NSImage *icon;
	CFStringNormalizationForm normalizationForm;
}
+ (id)renameItemWithPath:(NSString *)path;
+ (id)renameItemWithPath:(NSString *)path normalization:(CFStringNormalizationForm)nf;
+ (id)renameItemWithHFSPath:(NSString *)path;
+ (id)renameItemWithHFSPath:(NSString *)path normalization:(CFStringNormalizationForm)nf;

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
- (void)setNormalizationForm:(CFStringNormalizationForm)nf;

- (void)nameChanged;

@end
