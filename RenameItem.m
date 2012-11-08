#import "RenameItem.h"
#import "StringExtra.h"
#import "PathExtra.h"

#define useLog 0

@implementation RenameItem


static NSMutableDictionary *renameItemsPool = nil;

+ (void)initialize
{	
	if (!renameItemsPool) {
		CFDictionaryValueCallBacks dictvalue_callbacks = kCFTypeDictionaryValueCallBacks;
		dictvalue_callbacks.retain = NULL;
		dictvalue_callbacks.release = NULL;
		renameItemsPool = (NSMutableDictionary *)CFDictionaryCreateMutable(kCFAllocatorDefault, 0, 
											   &kCFTypeDictionaryKeyCallBacks, &dictvalue_callbacks);
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
	[renameItemsPool removeObjectForKey:hfsPath];
	[renameItemsPool removeObjectForKey:posixPath];
	[posixPath release];
	[hfsPath release];
	[newName release];
	[oldName release];
	[textColor release];
	[super dealloc];
}

#pragma mark public
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
	instance = [renameItemsPool objectForKey:path];
	if (!instance) {
#if useLog
		NSLog(@"can't find instance in the pool.");
#endif		
		instance = [[self new] autorelease];
		[instance setNormalizationForm:nf];
		[instance setHfsPath:path];
		[renameItemsPool setObject:instance forKey:path];
	}
	return instance;
}

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
	instance = [renameItemsPool objectForKey:path];
	if (!instance) {
#if useLog
		NSLog(@"can't find instance in the pool.");
#endif		
		instance = [[self new] autorelease];
		[instance setNormalizationForm:nf];
		[instance setPosixPath:path];
		[renameItemsPool setObject:instance forKey:path];
	}
	return instance;
}

- (void)nameChanged
{
	[self setOldName:newName];
	[self setNewName:nil];
}

- (void)resolveIcon
{
	NSImage *image = [[NSWorkspace sharedWorkspace] iconForFile:posixPath];
	[self setIcon:image];
}

#if MAC_OS_X_VERSION_MIN_REQUIRED >= 1050
- (BOOL)appyNewNameAndRetunError:(NSError **)error
{
	NSFileManager *fm = [NSFileManager new];
	NSString *new_path = [[posixPath stringByDeletingLastPathComponent] 
									stringByAppendingPathComponent:newName];
	BOOL result = [fm moveItemAtPath:posixPath toPath:new_path error:error];
	[fm release];
	return result;
}
#endif

#pragma mark accessors
- (void)setHfsPath:(NSString *)aPath
{
	[aPath retain];
	[hfsPath autorelease];
	hfsPath = aPath;
	[self setPosixPath:[hfsPath posixPath]];
}

- (NSString *)hfsPath
{
	return hfsPath;
}
	
- (void)setPosixPath:(NSString *)aPath
{
	[aPath retain];
	[posixPath autorelease];
	posixPath = aPath;
	[self setOldName:
		[[posixPath lastPathComponent] normalizedString:normalizationForm]];

	[self setNewName:nil];
}

- (NSString *)posixPath
{
	return posixPath;
}

- (void)setOldName:(NSString *)name
{
	[name retain];
	[oldName autorelease];
	oldName = name;
}

- (NSString *)oldName
{
	return oldName;
}

- (void)setNewName:(NSString *)name
{
	[name retain];
	[newName autorelease];
	newName = name;
	if (newName) {
		if ([newName isEqualToString:oldName]) {
			[self setTextColor:[NSColor grayColor]];
		} else {
			[self setTextColor:[NSColor blackColor]];
		}
	} else {
		[self setTextColor:[NSColor blackColor]];
	}
}

- (NSString *)newName
{
	return newName;
}

- (void)setTextColor:(NSColor *)color
{
	[color retain];
	[textColor autorelease];
	textColor = color;	
}

- (NSColor *)textColor
{
	return textColor;
}

- (NSImage *)icon
{
	return icon;
}

- (void)setIcon:(NSImage *)image
{
	[image retain];
	[icon autorelease];
	icon = image;
}

- (void)setNormalizationForm:(CFStringNormalizationForm)nf
{
	normalizationForm = nf;
}

@end
