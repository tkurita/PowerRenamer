#import "RenameItem.h"
#import "StringExtra.h"

#define useLog 1

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

- (oneway void)release
{
#if useLog
	NSLog(@"start release in RenameItem");
#endif		
	[super release];
}

- (void)dealloc
{
#if useLog
	NSLog(@"start dealloc in RenameItem");
#endif			
	[renameItemsPool removeObjectForKey:filePath];
	[filePath release];
	[newName release];
	[oldName release];
	[textColor release];
	[super dealloc];
}

#pragma mark public
+ (id)renameItemWithPath:(NSString *)path
{
	NSLog([renameItemsPool description]);
	path = [path normalizedString:kCFStringNormalizationFormKC];
	id instance = nil;
	instance = [renameItemsPool objectForKey:path];
	if (!instance) {
		NSLog(@"No pooled instance.");
		instance = [[self new] autorelease];
		[instance setFilePath:path];
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
	NSImage *image = [[NSWorkspace sharedWorkspace] iconForFile:filePath];
	[self setIcon:image];
}

#pragma mark accessors
- (void)setFilePath:(NSString *)aPath
{
	[aPath retain];
	[filePath autorelease];
	filePath = aPath;
	[self setOldName:[filePath lastPathComponent]];
	[self setNewName:nil];
}

- (NSString *)filePath
{
	return filePath;
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
