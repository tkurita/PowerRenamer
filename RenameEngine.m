#import "RenameEngine.h"
#import "RegexKitLite.h"
#import "PathExtra.h"
#import "StringExtra.h"

typedef enum RenameMode RenameMode;

#define useLog 0

static OSAScript *FINDER_SELECTION_CONTROLLER;

@implementation RenameEngine

+ (void)initialize
{
	NSString *path = [[NSBundle mainBundle] pathForResource:@"FinderSelectionController"
													 ofType:@"scpt" inDirectory:@"Scripts"];
	NSDictionary *err_info = nil;
	FINDER_SELECTION_CONTROLLER = [[OSAScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path]
																   error:&err_info];
	if (err_info) {
		NSLog([err_info description]);
	}
}

- (id)init {
    if (self = [super init]) {
		NSDictionary *error = nil;
		NSData *data = [FINDER_SELECTION_CONTROLLER compiledDataForType:@"scpt" usingStorageOptions:OSANull error:&error];
		finderSelectionController = [[OSAScript alloc] initWithCompiledData:data error:&error];
		/* confirm no shared script instance between finderSelectionController and FINDER_SELECTION_CONTROLLER
		NSAppleEventDescriptor *script_result = [FINDER_SELECTION_CONTROLLER executeHandlerWithName:@"get_finderselection" arguments:nil error:&error];
		NSLog([script_result description]);
		script_result = [finderSelectionController executeHandlerWithName:@"selected_items" arguments:nil error:&error];
		NSLog([script_result description]);
		*/
    }
    return self;
}

- (void)dealloc
{
	[finderSelectionController release];
	[targetDicts release];
	[super dealloc];
}

#pragma mark narrow down

- (BOOL)selectInFinder:(NSArray *)array error:(NSError **)error
{
	NSDictionary *err_info = nil;
	[finderSelectionController executeHandlerWithName:@"select_items"
									arguments:[NSArray arrayWithObject:array] error:&err_info];
	
	if (err_info) {
		NSString *msg = [NSString stringWithFormat:@"AppleScript Error : %@ (%@)",
						 [err_info objectForKey:OSAScriptErrorMessage],
						 [err_info objectForKey:OSAScriptErrorNumber]];
		NSDictionary *udict = [NSDictionary dictionaryWithObject:msg
														  forKey:NSLocalizedDescriptionKey];
		*error = [NSError errorWithDomain:@"PowerRenamerError" code:1 userInfo:udict];
		return NO;
	}
	return YES;
}

- (BOOL)narrowDownWithRegex:(id<RenameOptionsProtocol>)optionProvider error:(NSError **)error
{
	NSString *old_text = [optionProvider oldText];
	if ([old_text isEqualToString:@""]) {
		NSString *msg = NSLocalizedString(@"EnterSearchText", @"");
		NSDictionary *udict = [NSDictionary dictionaryWithObject:msg
														  forKey:NSLocalizedDescriptionKey];
		*error = [NSError errorWithDomain:@"PowerRenamerError" code:3 userInfo:udict];
		return NO;
	}
	
	NSMutableArray *matchitems = [NSMutableArray arrayWithCapacity:[targetDicts count]];
	NSEnumerator *enumerator = [targetDicts objectEnumerator];
	NSMutableDictionary *dict = nil;
	while (dict = [enumerator nextObject]) {
		NSString *oldname = [dict objectForKey:@"oldName"];
		if( [oldname isMatchedByRegex:old_text options:RKLNoOptions
								inRange:NSMakeRange(0, [oldname length]) error:error]) {
			[matchitems addObject:[dict objectForKey:@"path"]];
		}
		if (*error) {
			return NO;
		}
	}
	
	if (![self selectInFinder:matchitems error:error]) {
		NSLog([*error description]);
		return NO;
	}
	
	return YES;
}

- (BOOL)narrowDownWithMode:(id<RenameOptionsProtocol>)optionProvider error:(NSError **)error
{
	NSString *old_text = [optionProvider oldText];
	if ([old_text isEqualToString:@""]) {
		NSString *msg = NSLocalizedString(@"EnterSearchText", @"");
		NSDictionary *udict = [NSDictionary dictionaryWithObject:msg
														  forKey:NSLocalizedDescriptionKey];
		*error = [NSError errorWithDomain:@"PowerRenamerError" code:3 userInfo:udict];
		return NO;
	}
	
	int compopt = NSCaseInsensitiveSearch;
	unsigned int mode = [optionProvider modeIndex];
	switch (mode) {
		case kStartsWithMode:
			compopt = compopt|NSAnchoredSearch;
			break;
		case kEndsWithMode:
			compopt = compopt|NSBackwardsSearch;
			break;
		default:
			break;
	}	
	
	NSDictionary *dict = nil;
	NSMutableArray *matchitems = [NSMutableArray arrayWithCapacity:[targetDicts count]];
	NSEnumerator *enumerator = [targetDicts objectEnumerator];	
	while (dict = [enumerator nextObject]) {
		NSString *oldname = [dict objectForKey:@"oldName"];
		NSRange range = [oldname rangeOfString:old_text options:compopt];
		if (range.length) {
			[matchitems addObject:[dict objectForKey:@"path"]];
		}
	}
	
	if (![self selectInFinder:matchitems error:error]) {
		NSLog([*error description]);
		return NO;
	}
		
	return YES;
}

- (BOOL)narrowDownTargetItems:(id<RenameOptionsProtocol>)optionProvider error:(NSError **)error
{
	unsigned int mode = [optionProvider modeIndex];
	BOOL result = NO;
	switch (mode) {
		case kContainMode:
		case kStartsWithMode:
		case kEndsWithMode:
			result = [self narrowDownWithMode:optionProvider error:error];
			break;
		case kRegexMode:
		case kNumberingMode:
			result = [self narrowDownWithRegex:optionProvider error:error];
			break;
		default:
			break;
	}
	
	return result;	
}

#pragma mark rename

- (BOOL)replaceSubstringWithMode:(id<RenameOptionsProtocol>)optionProvider error:(NSError **)error
{
	NSString *old_text = [optionProvider oldText];
	NSString *new_text = [optionProvider newText];
	unsigned int mode = [optionProvider modeIndex];
	if ((mode == kContainMode) && ([old_text isEqualToString:@""])) {
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
			case kEndsWithMode:
				range = NSMakeRange([newname length] - [old_text length], [old_text length]);
				break;
			case kContainMode:
				range = NSMakeRange(0, [newname length]);
				break;
		}
		[newname replaceOccurrencesOfString:old_text withString:new_text 
									options:NSCaseInsensitiveSearch range:range];
		
		if (![newname isEqualToString:oldname]) {
			newname = [[newname uniqueNameAtLocation:
										[[dict objectForKey:@"path"] stringByDeletingLastPathComponent]
								   excepting:[targetDicts valueForKey:@"newName"]] mutableCopy];
			[dict setObject:[NSColor blackColor] forKey:@"textColor"];			
		} else {
			[dict setObject:[NSColor grayColor] forKey:@"textColor"];
		}
		[dict setObject:newname forKey:@"newName"];
	}
	
	return YES;
}

- (BOOL)replaceWithRegex:(id<RenameOptionsProtocol>)optionProvider error:(NSError **)error
{
	NSString *old_text = [optionProvider oldText];
	NSString *new_text_orig = [optionProvider newText];
	unsigned int mode = [optionProvider modeIndex];
	NSString *numbering_format = nil;
	if (mode == kNumberingMode) {
		if ([optionProvider leadingZeros]) {
			int len = [targetDicts count];
			int totalfigure = 0;
			while(len > 1) {
				totalfigure++;
				len = len/10;
			}
			numbering_format = [NSString stringWithFormat:@"%%0%dd", totalfigure];
		} else {
			numbering_format = @"%d";
		}
	}
	
	NSEnumerator *enumerator = [targetDicts objectEnumerator];
	NSMutableDictionary *dict = nil;
	int n = [[optionProvider startingNumber] intValue];
	NSMutableString *new_text = [new_text_orig mutableCopy];
	while (dict = [enumerator nextObject]) {
		NSString *oldname = [dict objectForKey:@"oldName"];
		NSString *newname = nil;
		if (mode == kNumberingMode) {
			new_text = [new_text_orig mutableCopy];
			[new_text replaceOccurrencesOfString:@"$#" 
								   withString:[NSString stringWithFormat:numbering_format, n]
											  options:0 range:NSMakeRange(0, [new_text length])];
					
		}
		
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
				[dict setObject:[NSColor blackColor] forKey:@"textColor"];
			} else {
				[dict setObject:[NSColor grayColor] forKey:@"textColor"];
			}
			[dict setObject:newname forKey:@"newName"];
		} else {
			[dict setObject:oldname forKey:@"newName"];
			[dict setObject:[NSColor grayColor] forKey:@"textColor"];
		}
		n++;
	}
	return YES;
}

- (BOOL)resolveNewNames:(id<RenameOptionsProtocol>)optionProvider error:(NSError **)error
{
	unsigned int mode = [optionProvider modeIndex];
	BOOL result = NO;
	switch (mode) {
		case kContainMode:
		case kStartsWithMode:
		case kEndsWithMode:
			result = [self replaceSubstringWithMode:optionProvider error:error];
			break;
		case kRegexMode:
		case kNumberingMode:
			result = [self replaceWithRegex:optionProvider error:error];
			break;
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

- (BOOL)resolveTargetItemsWithSorting:(BOOL)sortFlag error:(NSError **)error
{
	NSDictionary *err_info = nil;
	NSAppleEventDescriptor *script_result = nil;
	if (sortFlag) {
		script_result = [finderSelectionController executeHandlerWithName:@"sorted_finderselection"
																arguments:nil error:&err_info];
	} else {
		script_result = [finderSelectionController executeHandlerWithName:@"get_finderselection"
																arguments:nil error:&err_info];
	}
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
		NSString *path = [[[script_result descriptorAtIndex:i] stringValue] normalizedString:kCFStringNormalizationFormKC];
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
