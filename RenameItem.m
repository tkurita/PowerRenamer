#import "RenameItem.h"
#import "StringExtra/StringExtra.h"
#import "PathExtra/PathExtra.h"

#define useLog 0

@implementation RenameItem

static NSMutableDictionary *renameItemsPool = nil;

+ (void)initialize
{	
	if (!renameItemsPool) {
		CFDictionaryValueCallBacks dictvalue_callbacks = kCFTypeDictionaryValueCallBacks;
		dictvalue_callbacks.retain = NULL;
		dictvalue_callbacks.release = NULL;
		renameItemsPool = (NSMutableDictionary *)CFBridgingRelease(CFDictionaryCreateMutable(kCFAllocatorDefault, 0, 
											   &kCFTypeDictionaryKeyCallBacks, &dictvalue_callbacks));
	}
}

#if useLog
- (oneway void)release
{
	NSLog(@"start release in RenameItem");	
	[super release];
}
#endif

- (void)dealloc
{
#if useLog
	NSLog(@"start dealloc in RenameItem");
#endif
#if useDeprecated
	if (_hfsPath) [renameItemsPool removeObjectForKey:_hfsPath];
#endif
	if (_posixPath) [renameItemsPool removeObjectForKey:_posixPath];
}

#pragma mark public
#if useDeprecated
+ (id)renameItemWithHFSPath:(NSString *)path
{
	return [self renameItemWithHFSPath:path normalization:kCFStringNormalizationFormC];
}

+ (id)renameItemWithHFSPath:(NSString *)path normalization:(CFStringNormalizationForm)nf
{
#if useLog
	NSLog([renameItemsPool description]);
#endif
	id instance = nil;
	instance = renameItemsPool[path];
	if (!instance) {
#if useLog
		NSLog(@"can't find instance in the pool.");
#endif		
		instance = [self new];
		[instance setNormalizationForm:nf];
		[instance setHfsPath:path];
		renameItemsPool[path] = instance;
	}
	return instance;
}
#endif

+ (id)renameItemWithPath:(NSString *)path
{
	return [self renameItemWithPath:path normalization:kCFStringNormalizationFormC];
}

+ (id)renameItemWithPath:(NSString *)path normalization:(CFStringNormalizationForm)nf
{
#if useLog
	NSLog([renameItemsPool description]);
#endif
	id instance = nil;
	instance = renameItemsPool[path];
	if (!instance) {
#if useLog
		NSLog(@"can't find instance in the pool.");
#endif		
		instance = [self new];
		[instance setNormalizationForm:nf];
		[instance setPosixPath:path];
		renameItemsPool[path] = instance;
	}
	return instance;
}

- (void)nameChanged
{
	[self setOldName:_nuName];
	self.nuName = nil;
}

- (void)resolveIcon
{
	NSImage *image = [[NSWorkspace sharedWorkspace] iconForFile:_posixPath];
	[self setIcon:image];
}

- (BOOL)appyNewNameAndRetunError:(NSError **)error
{
	NSFileManager *fm = [NSFileManager new];
	NSString *new_path = [[_posixPath stringByDeletingLastPathComponent]
									stringByAppendingPathComponent:_nuName];
	BOOL result = [fm moveItemAtPath:_posixPath toPath:new_path error:error];
	return result;
}

#pragma mark accessors
#if useDeprecated
- (void)setHfsPath:(NSString *)aPath
{
	if (_hfsPath != aPath) {
        _hfsPath = nil;
        _hfsPath = aPath;
        [self setPosixPath:[_hfsPath posixPath]];
    }
}
#endif

- (void)setPosixPath:(NSString *)aPath
{
	if (_posixPath != aPath) {
        _posixPath = nil;
        _posixPath = aPath;
        [self setOldName:
         [[_posixPath lastPathComponent] normalizedString:normalizationForm]];
        
        self.nuName = nil;
    }
}

- (void)setNuName:(NSString *)name
{
	if (_nuName != name) {
        _nuName = nil;
        _nuName = name;
        if (_nuName) {
            if ([_nuName isEqualToString:_oldName]) {
                [self setTextColor:[NSColor grayColor]];
            } else {
                [self setTextColor:[NSColor blackColor]];
            }
        } else {
            [self setTextColor:[NSColor blackColor]];
        }
    }
}

- (void)setNormalizationForm:(CFStringNormalizationForm)nf
{
	normalizationForm = nf;
}

@end
