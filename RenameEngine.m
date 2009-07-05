#import "RenameEngine.h"
#import "RegexKitLite.h"
#import "PathExtra.h"


#define ANYSUBSTRING_MODE 0
#define BEGINNING_MODE 1
#define ENDDING_MODE 2
#define REGEX_MODE 3

@implementation RenameEngine

- (id)init {
    if (self = [super init]) {
		NSString *path = [[NSBundle mainBundle] pathForResource:@"FinderSelectionController"
														 ofType:@"scpt" inDirectory:@"Scripts"];
		NSDictionary *err_info = nil;
		finderSelectionController = [[OSAScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path]
																	   error:&err_info];
		if (err_info) {
			NSLog([err_info description]);
			[self autorelease];
			return nil;
		}
    }
    return self;
}

- (void)dealloc
{
	[finderSelectionController release];
	[targetDicts release];
	[super dealloc];
}

- (BOOL)replaceSubstringWithMode:(id<RenameOptionsProtocol>)optionProvider error:(NSError **)error
{
	NSString *old_text = [optionProvider oldText];
	NSString *new_text = [optionProvider newText];
	unsigned int mode = [optionProvider modeIndex];
	if ((mode == ANYSUBSTRING_MODE) && ([old_text isEqualToString:@""])) {
		NSString *msg = NSLocalizedString(@"EnterSearchText", @"");
		NSDictionary *udict = [NSDictionary dictionaryWithObject:msg
												  forKey:NSLocalizedDescriptionKey];
		*error = [NSError errorWithDomain:@"PowerRenamerError" code:3 userInfo:udict];
		return NO;
	}
	
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
	
	return YES;
}

- (BOOL)replaceWithRegex:(id<RenameOptionsProtocol>)optionProvider error:(NSError **)error
{
	NSString *old_text = [optionProvider oldText];
	NSString *new_text = [optionProvider newText];
	
	NSEnumerator *enumerator = [targetDicts objectEnumerator];
	NSMutableDictionary *dict = nil;
	
	while (dict = [enumerator nextObject]) {
		NSString *oldname = [dict objectForKey:@"oldName"];
		NSString *newname = nil;
		newname = [oldname stringByReplacingOccurrencesOfRegex:old_text
													withString:new_text
													   options:RKLNoOptions
														 range:NSMakeRange(0, [oldname length])
														 error:error];
		if (*error) {
			return NO;
		}
		
		if (newname) {
			if (![newname isEqualToString:oldname]) {
				newname = [newname uniqueNameAtLocation:[[dict objectForKey:@"path"] stringByDeletingLastPathComponent]
											  excepting:[targetDicts valueForKey:@"newName"]];
			}
			[dict setObject:newname forKey:@"newName"];
		} else {
			[dict setObject:oldname forKey:@"newName"];
		}
	}
	return YES;
}

- (BOOL)resolveNewNames:(id<RenameOptionsProtocol>)optionProvider error:(NSError **)error
{
	unsigned int mode = [optionProvider modeIndex];
	BOOL result = NO;
	switch (mode) {
		case ANYSUBSTRING_MODE:
		case BEGINNING_MODE:
		case ENDDING_MODE:
			result = [self replaceSubstringWithMode:optionProvider error:error];
			break;
		case REGEX_MODE:
			result = [self replaceWithRegex:optionProvider error:error];
		default:
			break;
	}
	
	return result;
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
	NSAppleEventDescriptor *script_result = [finderSelectionController executeHandlerWithName:@"get_finderselection"
																			arguments:nil error:&err_info];
	BOOL result = NO;
	if (err_info) {
#if useLog
		NSLog([err_info description]);
#endif
		NSString *msg = [NSString stringWithFormat:@"AppleScript Error : %@ (%@)",
										[err_info objectForKey:OSAScriptErrorMessage],
										 [err_info objectForKey:OSAScriptErrorNumber]];
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

- (BOOL)processRenameAndReturnError:(NSError **)error
{
	NSArray *oldnames = [targetDicts valueForKey:@"oldName"];
	NSArray *newnames = [targetDicts valueForKey:@"newName"];
	NSDictionary *err_info = nil;
	[finderSelectionController executeHandlerWithName:@"process_rename" 
			arguments:[NSArray arrayWithObjects:oldnames, newnames, nil]
												error:&err_info];
	NSLog([err_info description]);
	if (err_info) {
#if useLog
		NSLog([err_info description]);
#endif
		NSString *msg = [NSString stringWithFormat:@"AppleScript Error : %@ (%@)",
						 [err_info objectForKey:OSAScriptErrorMessage],
						 [err_info objectForKey:OSAScriptErrorNumber]];
		NSDictionary *udict = [NSDictionary dictionaryWithObject:msg
														  forKey:NSLocalizedDescriptionKey];
		*error = [NSError errorWithDomain:@"PowerRenamerError" code:2 userInfo:udict];		
		
		return NO;
	}
	/*
	NSFileManager *filemanager = [NSFileManager defaultManager];
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	NSEnumerator *enumerator = [targetDicts objectEnumerator];
	NSMutableDictionary *dict = nil;
	while (dict = [enumerator nextObject]) {
		NSString *newname = [dict objectForKey:@"newName"];
		NSString *oldname = [dict objectForKey:@"oldName"];
		if (![oldname isEqualToString:newname]) {
			NSString *path = [dict objectForKey:@"path"];
			NSString *newpath = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:newname];
			[filemanager movePath:path toPath:newpath handler:nil];
			[workspace selectFile:newpath inFileViewerRootedAtPath:@""];
		}
	}
	 */
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
