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
		[instance setHfsPath:path];
		[renameItemsPool setObject:instance forKey:path];
	}
	return instance;
}

+ (id)renameItemWithPath:(NSString *)path
{
#if useLog
	NSLog([renameItemsPool description]);
#endif
	path = [path normalizedString:kCFStringNormalizationFormKC];
	id instance = nil;
	instance = [renameItemsPool objectForKey:path];
	if (!instance) {
#if useLog
		NSLog(@"can't find instance in the pool.");
#endif		
		instance = [[self new] autorelease];
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
//	[self setOldName:
//		[[posixPath lastPathComponent] normalizedString:kCFStringNormalizationFormKC]];
	[self setOldName:
		[[posixPath lastPathComponent] normalizedString:kCFStringNormalizationFormC]];

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

@end
