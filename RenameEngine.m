#import "RenameEngine.h"
//#import "RegexKitLite.h"
#import "PathExtra.h"
#import "StringExtra.h"
#import "RenameItem.h"

typedef enum RenameMode RenameMode;

#define useLog 0

static OSAScript *FINDER_SELECTION_CONTROLLER;

@implementation RenameEngine

+ (void)initialize
{
	NSString *path = [[NSBundle mainBundle] pathForResource:@"FinderSelectionController"
													 ofType:@"scpt"];
	NSDictionary *err_info = nil;
	FINDER_SELECTION_CONTROLLER = [[OSAScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path]
																   error:&err_info];
	if (err_info) {
		NSLog(@"%@", [err_info description]);
	}	
	[FINDER_SELECTION_CONTROLLER executeHandlerWithName:@"initialize" arguments:nil error:&err_info];
	if (err_info) {
		NSLog(@"%@", [err_info description]);
	}
}

CFStringNormalizationForm UnicodeNormalizationForm()
{
	int unf = [[NSUserDefaults standardUserDefaults] integerForKey:@"UnicodeNormalizationIndex"];
	CFStringNormalizationForm result;
	switch (unf) {
		case 0:
			result = kCFStringNormalizationFormD;
			break;
		case 1:
			result = kCFStringNormalizationFormC;
			break;
		case 2:
			result = kCFStringNormalizationFormKD;
			break;
		case 3:
			result = kCFStringNormalizationFormKC;
			break;
		default:
			result = kCFStringNormalizationFormC;
			break;
	}
	
	return result;
}

- (id)init {
    if (self = [super init]) {
		NSError *error = nil;
        NSDictionary *err_dict = nil;
		NSData *data = [FINDER_SELECTION_CONTROLLER compiledDataForType:@"scpt" usingStorageOptions:OSANull error:&err_dict];
        finderSelectionController = [[OSAScript alloc] initWithCompiledData:data
                                                        fromURL:nil
                                    usingStorageOptions:OSADontSetScriptLocation
                                                                      error:&error];
		hasNewNames = NO;
		normalizationForm = UnicodeNormalizationForm();
    }
    return self;
}

- (void)dealloc
{
#if useLog
	NSLog(@"start dealloc in RenameEngine");
#endif	
	[finderSelectionController release];
#if useLog
	NSLog(@"targetDicts retainCount:%u", [targetDicts retainCount]);
#endif
	[targetDicts release];
	[super dealloc];
}

#pragma mark public
- (void)clearTargets
{
	[self setTargetDicts:nil];
	hasNewNames = NO;
}

#pragma mark method for static mode
- (void)clearNewNames
{
	if (!targetDicts) return;
	NSEnumerator *enumerator = [targetDicts objectEnumerator];
	RenameItem *item;
	while (item = [enumerator nextObject]) {
		[item setNewName:nil];
	}
	hasNewNames = NO;
	[self setRenamedItems:nil];
}


- (void)setTargetFiles:(NSArray *)filenames
{
	NSMutableArray *target_dicts = [NSMutableArray arrayWithCapacity:[filenames count]];
	NSEnumerator *enumerator = [filenames objectEnumerator];
	NSString *path;
	while (path = [enumerator nextObject]) {
		RenameItem *rename_item = [RenameItem renameItemWithHFSPath:[path hfsPath] normalization: normalizationForm];
		[target_dicts addObject:rename_item];
	}
	[self setTargetDicts:target_dicts];
}

#pragma mark narrow down
- (BOOL)selectInFinderReturningError:(NSError **)error
{
	NSArray *array = [targetDicts valueForKey:@"hfsPath"];
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
	NSRegularExpressionOptions opts = 0;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"IgnoreCases"]) {
		opts = opts | NSRegularExpressionCaseInsensitive;
	}
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:old_text
                                                                           options:opts
                                                                             error:error];
    if (*error) return NO;
	for (RenameItem *item in targetDicts) {
		NSString *oldname = [item oldName];
        if ([regex numberOfMatchesInString:oldname
                                   options:0 range:NSMakeRange(0, [oldname length])] > 0) {
			[matchitems addObject:item];
		}
	}
	
	[self setTargetDicts:matchitems];
	
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
	SEL selector = nil;
	switch (mode) {
		case kStartsWithMode:
			selector = @selector(hasPrefix:options:);
			break;
		case kEndsWithMode:
			selector = @selector(hasSuffix:options:);
			break;
		case kContainMode:
			selector = @selector(contain:options:);
			break;
		default:
			break;
	}
	
	NSMethodSignature *signature = [NSString instanceMethodSignatureForSelector:selector];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	[invocation setSelector:selector];
	[invocation setArgument:&old_text atIndex:2];
	[invocation setArgument:&compopt atIndex:3];
	
	NSMutableArray *matchitems = [NSMutableArray arrayWithCapacity:[targetDicts count]];
	NSEnumerator *enumerator = [targetDicts objectEnumerator];	
	RenameItem *item = nil;
	while (item = [enumerator nextObject]) {
		NSString *oldname = [item oldName];
		[invocation setTarget:oldname];
		[invocation invoke];
		BOOL result = NO;
		[invocation getReturnValue:&result];
		if (result) {
			[matchitems addObject:item];
		}
	}
	[self setTargetDicts:matchitems];
		
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
	NSString *old_text = [[optionProvider oldText] normalizedString:normalizationForm];
	NSString *new_text = [optionProvider newText];
	unsigned int mode = [optionProvider modeIndex];
	if ((mode == kContainMode) && ([old_text isEqualToString:@""])) {
		NSString *msg = NSLocalizedString(@"EnterSearchText", @"");
		NSDictionary *udict = [NSDictionary dictionaryWithObject:msg
												  forKey:NSLocalizedDescriptionKey];
		*error = [NSError errorWithDomain:@"PowerRenamerError" code:3 userInfo:udict];
		return NO;
	}
	
	NSUInteger opt = 0;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"IgnoreCases"]) {
		opt = opt | NSCaseInsensitiveSearch;
	}
	SEL selector = nil;
	switch (mode) {
		case kStartsWithMode:
			selector = @selector(replacePrefixOfString:withString:options:);
			break;			
		case kEndsWithMode:
			selector = @selector(replaceSuffixOfString:withString:options:);
			break;
		case kContainMode:
			selector = @selector(replaceSubtextOfString:withString:options:);
			break;
		default:
			break;
	}
	NSMethodSignature *signature = [NSMutableString instanceMethodSignatureForSelector:selector];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	[invocation setSelector:selector];
	[invocation setArgument:&old_text atIndex:2];
	[invocation setArgument:&new_text atIndex:3];
	[invocation setArgument:&opt atIndex:4];
	
	NSEnumerator *enumerator = [targetDicts objectEnumerator];
	RenameItem *item = nil;
	NSMutableArray *renamed_items = [NSMutableArray array];
	NSMutableDictionary *newnames_dict = [NSMutableDictionary dictionary];
	while (item = [enumerator nextObject]) {
		NSString *oldname = [item oldName];
		NSMutableString *newname = [oldname mutableCopy];
		[invocation setTarget:newname];
		[invocation invoke];
		unsigned int result = 0;
		[invocation getReturnValue:&result];
		if (result && ![newname isEqualToString:oldname]) {
			NSString *dirpath = [[item posixPath] stringByDeletingLastPathComponent];
			NSMutableArray *newnames_indir = [newnames_dict objectForKey:dirpath];
			newname = [[newname uniqueNameAtLocation:dirpath
									   excepting:newnames_indir] mutableCopy];
			if (!newnames_indir) {
				newnames_indir = [NSMutableArray array];
			}
			[newnames_indir addObject:newname];
			[item setNewName:newname];
			[renamed_items addObject:item];
		} else {
			[item setNewName:newname];
		}
	}
	[self setRenamedItems:renamed_items];
	return YES;
}

- (BOOL)replaceWithRegex:(id<RenameOptionsProtocol>)optionProvider error:(NSError **)error
{
	NSString *old_text = [optionProvider oldText];
	NSString *new_text_orig = [optionProvider newText];
	unsigned int mode = [optionProvider modeIndex];
	NSString *numbering_format = nil;
	int n = [[optionProvider startingNumber] intValue];
	
	if (mode == kNumberingMode) {
		if ([optionProvider leadingZeros]) {
			int len = [targetDicts count] + (n-1);
			int totalfigure = 1;
			while(len >= 10) {
				totalfigure++;
				len = len/10;
			}
			numbering_format = [NSString stringWithFormat:@"%%0%dd", totalfigure];
		} else {
			numbering_format = @"%d";
		}
	}
	
	NSMutableArray *renamed_items = [NSMutableArray array];
	NSMutableDictionary *newnames_dict = [NSMutableDictionary dictionary];
	NSMutableString *new_text = [new_text_orig mutableCopy];
	NSRegularExpressionOptions opts = 0;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"IgnoreCases"]) {
		opts = opts | NSRegularExpressionCaseInsensitive;
	}
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:old_text
                                                                           options:opts
                                                                             error:error];
    if (*error) return NO;
	for (RenameItem *item in targetDicts) {
		NSString *oldname = [item oldName];
		NSMutableString *newname = [oldname mutableCopy];
		if (mode == kNumberingMode) {
			new_text = [new_text_orig mutableCopy];
			[new_text replaceOccurrencesOfString:@"$#" 
								   withString:[NSString stringWithFormat:numbering_format, n]
											  options:0 range:NSMakeRange(0, [new_text length])];
		}
         NSUInteger nreplace = [regex replaceMatchesInString:newname
                                                     options:0
                                                       range:NSMakeRange(0, [oldname length])
                                                withTemplate:new_text];            
        if (nreplace) n++;
		if (newname && ![newname length]) {
            newname = nil;
		}
		
		if (newname && ![newname isEqualToString:oldname])  {
			NSString *dirpath = [[item posixPath] stringByDeletingLastPathComponent];
			NSMutableArray *newnames_indir = [newnames_dict objectForKey:dirpath];
			newname = [[newname uniqueNameAtLocation:dirpath
										   excepting:newnames_indir] mutableCopy];
			if (!newnames_indir) {
				newnames_indir = [NSMutableArray array];
			}
			[newnames_indir addObject:newname];
			[item setNewName:newname];
			[renamed_items addObject:item];
		} else {
			[item setNewName:newname];
		}
	}
	[self setRenamedItems:renamed_items];
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
	hasNewNames = result;
	return result;
}

- (BOOL)resolveIcons
{
	[targetDicts makeObjectsPerformSelector:@selector(resolveIcon)];
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
		NSString *path = [[script_result descriptorAtIndex:i] stringValue];
		RenameItem *rename_item = [RenameItem renameItemWithHFSPath:path normalization:normalizationForm];
		[target_dicts addObject:rename_item];
	}
	result = YES;
	[self setTargetDicts:target_dicts];
bail:
	if (result) isSorted = sortFlag;
	return result;
}

#if MAC_OS_X_VERSION_MIN_REQUIRED >= 1050
- (BOOL)applyNewNamesAndReturnError:(NSError **)error // rename with NSFileManager
{
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL result = NO;
	for (RenameItem *ritem in renamedItems) {
		NSString *src = [ritem posixPath];
		NSString *dest = [[src stringByDeletingLastPathComponent]
						  stringByAppendingPathComponent:[ritem newName]];
		result = [fm moveItemAtPath:src toPath:dest error:error];
		if (!result) break;
	}
	
	return result;
}
#endif

- (BOOL)processRenameAndReturnError:(NSError **)error // rename with Finder
{
	NSArray *pathes = [renamedItems valueForKey:@"hfsPath"];
	NSArray *newnames = [renamedItems valueForKey:@"newName"];
	NSDictionary *err_info = nil;
	id ignore_responses = [[NSUserDefaults standardUserDefaults] 
									objectForKey:@"ignoringFinderResponses"];
	[finderSelectionController executeHandlerWithName:@"process_rename" 
					arguments:[NSArray arrayWithObjects:pathes, newnames,
									ignore_responses, nil]
												error:&err_info];
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

	return YES;
}

#pragma mark Accessors

- (NSArray *)targetDicts
{
	return targetDicts;
}

- (void)setTargetDicts:(NSArray *)array
{
#if useLog
	NSLog(@"array in setTargetDicts retainCount:%u", [array retainCount]);
#endif
	if (hasNewNames && isSorted) {
		[self clearNewNames];
	}	
	[array retain];
	[targetDicts autorelease];
	targetDicts = array;
}

- (BOOL)hasNewNames
{
	return hasNewNames;
}

- (void)setRenamedItems:(NSArray *)array
{
	[array retain];
	[renamedItems autorelease];
	renamedItems = array;
}

- (BOOL)isSorted
{
	return isSorted;
}

@end
