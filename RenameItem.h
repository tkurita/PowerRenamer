#import <Cocoa/Cocoa.h>


@interface RenameItem : NSObject {
	CFStringNormalizationForm normalizationForm;
}
+ (id)renameItemWithPath:(NSString *)path;
+ (id)renameItemWithPath:(NSString *)path normalization:(CFStringNormalizationForm)nf;
+ (id)renameItemWithHFSPath:(NSString *)path;
+ (id)renameItemWithHFSPath:(NSString *)path normalization:(CFStringNormalizationForm)nf;

- (void)setNormalizationForm:(CFStringNormalizationForm)nf;
- (void)nameChanged;
- (void)resolveIcon;

@property (nonatomic, strong) NSString *hfsPath;
@property (nonatomic, strong) NSString *posixPath;
@property (nonatomic, strong) NSString *oldName;
@property (nonatomic, strong) NSString *nuName;
@property (nonatomic, strong) NSColor *textColor;
@property (nonatomic, strong) NSImage *icon;

@end
