#import "RenameEngine.h"
#import "RegexKitLite.h"
#import "PathExtra.h"

static NSAppleScript *getFinderSelection;

#define ANYSUBSTRING_MODE 0
#define BEGINNING_MODE 1
#define ENDDING_MODE 2
#define REGEX_MODE 3

@implementation RenameEngine

+ (void)initialize
{
	NSString *path = [[NSBundle mainBundle] pathForResource:@"GetFinderSelection"
											ofType:@"scpt" inDirectory:@"Scripts"];
	NSDictionary *errInfo;
	getFinderSelection = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path]
																error:&errInfo];
}

- (void)dealloc
{
	[targetDicts release];
	[super dealloc];
}

- (void)replaceSubstringWithMode:(int)mode
{
	NSUserDefaults *userdefaults = [NSUserDefaults standardUserDefaults];
	NSString *old_text = [userdefaults stringForKey:@"LastOldText"];
	NSString *new_text = [userdefaults stringForKey:@"LastNewText"];
	NSRange range = NSMakeRange(0, [old_text length]); // beginning mode
	
	NSEnumerator *enumerator = [targetDicts objectEnumerator];
	NSMutableDictionary *dict = nil;
	while (dict = [enumerator nextObject]) {
		NSString *oldname = [dict objectForKey:@"oldName"];
		NSMutableString *newname = [oldname mutableCopy];
		switch (mode) {
			case ENDDING_MODE:
				range = NSMakeRange([newname length] - [old_text length], [old_text length]);
				break;
			case ANYSUBSTRING_MODE:
				range = NSMakeRange(0, [newname length]);
				break;
		}
		[newname replaceOccurrencesOfString:old_text withString:new_text 
									options:NSCaseInsensitiveSearch range:range];
		if (![newname isEqualToString:oldname]) {
			newname = [[newname uniqueNameAtLocation:
										[[dict objectForKey:@"path"] stringByDeletingLastPathComponent]
								   excepting:[targetDicts valueForKey:@"newName"]] mutableCopy];
		}		
		[dict setObject:newname forKey:@"newName"];
	}
}

- (void)replaceWithRegex
{
	NSUserDefaults *userdefaults = [NSUserDefaults standardUserDefaults];
	NSString *old_text = [userdefaults stringForKey:@"LastOldText"];
	NSString *new_text = [userdefaults stringForKey:@"LastNewText"];
	
	NSEnumerator *enumerator = [targetDicts objectEnumerator];
	NSMutableDictionary *dict = nil;
	while (dict = [enumerator nextObject]) {					
		NSString *oldname = [dict objectForKey:@"oldName"];
		NSString *newname = [oldname stringByReplacingOccurrencesOfRegex:old_text
										withString:new_text];
		if (![newname isEqualToString:oldname]) {
			newname = [newname uniqueNameAtLocation:[[dict objectForKey:@"path"] stringByDeletingLastPathComponent]
										  excepting:[targetDicts valueForKey:@"newName"]];
		}
		[dict setObject:newname forKey:@"newName"];
	}
}

- (BOOL)resolveNewNames
{
	int mode = [[NSUserDefaults standardUserDefaults] integerForKey:@"ModeIndex"];
	switch (mode) {
		case ANYSUBSTRING_MODE:
		case BEGINNING_MODE:
		case ENDDING_MODE:
			[self replaceSubstringWithMode:mode];
			break;
		case REGEX_MODE:
			[self replaceWithRegex];
		default:
			break;
	}
	
	return YES;
}

- (BOOL)resolveIcons
{
	NSEnumerator *enumerator = [targetDicts objectEnumerator];
	NSMutableDictionary *dict = nil;
	while (dict = [enumerator nextObject]) {
		NSImage *icon = [[NSWorkspace sharedWorkspace] 
							iconForFile:[dict objectForKey:@"path"]];
		[dict setObject:icon forKey:@"icon"];
	}
	return YES;
}

- (BOOL)resolveTargetItemsAndReturnError:(NSError **)error
{
	NSDictionary *err_info = nil;
	NSAppleEventDescriptor *script_result = [getFinderSelection executeAndReturnError:&err_info];
	BOOL result = NO;
	if (err_info != nil) {
#if useLog
		NSLog([err_info description]);
#endif
		NSString *msg = [NSString stringWithFormat:@"AppleScript Error : %@ (%@)",
										[err_info objectForKey:NSAppleScriptErrorMessage],
										 [err_info objectForKey:NSAppleScriptErrorNumber]];
		NSDictionary *udict = [NSDictionary dictionaryWithObject:msg
										  forKey:NSLocalizedDescriptionKey];
		*error = [NSError errorWithDomain:@"PowerRenamerError" code:1 userInfo:udict];		

		goto bail;
	}
	unsigned int nfile = [script_result numberOfItems];
	if (!nfile) {
		NSDictionary *udict = [NSDictionary dictionaryWithObject:NSLocalizedString(@"NoSelection", @"")
														  forKey:NSLocalizedDescriptionKey];
		*error = [NSError errorWithDomain:@"PowerRenamerError" code:2 userInfo:udict];
		goto bail;
	}
	NSMutableArray *target_dicts = [NSMutableArray arrayWithCapacity:nfile];
	for (unsigned int i=1; i <= nfile; i++) {
		NSString *path = [[script_result descriptorAtIndex:i] stringValue];
		NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
											  path, @"path",
											  [path lastPathComponent], @"oldName", nil];
		
		[target_dicts addObject:dict];
	}
	result = YES;
	[self setTargetDicts:target_dicts];
bail:
	return result;
}

- (BOOL)processRename
{
	NSFileManager *filemanager = [NSFileManager defaultManager];
	NSEnumerator *enumerator = [targetDicts objectEnumerator];
	NSMutableDictionary *dict = nil;
	while (dict = [enumerator nextObject]) {
		NSString *newname = [dict objectForKey:@"newName"];
		NSString *oldname = [dict objectForKey:@"oldName"];
		if (![oldname isEqualToString:newname]) {
			NSString *path = [dict objectForKey:@"path"];
			NSString *newpath = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:newname];
			[filemanager movePath:path toPath:newpath handler:nil];
		}
	}
	return YES;
}

#pragma mark Accessors

- (NSArray *)targetDicts
{
	return targetDicts;
}

- (void)setTargetDicts:(NSArray *)array
{
	[array retain];
	[targetDicts autorelease];
	targetDicts = array;
}

@end
