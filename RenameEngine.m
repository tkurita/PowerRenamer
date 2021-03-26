#import "RenameEngine.h"
#import "PathExtra/PathExtra.h"
#import "StringExtra/StringExtra.h"
#import "RenameItem.h"

typedef enum RenameMode RenameMode;

#define useLog 0

static OSAScript *FINDER_SELECTION_CONTROLLER;

@implementation RenameEngine
@synthesize targetDicts = _targetDicts;

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
	[FINDER_SELECTION_CONTROLLER executeHandlerWithName:@"initialize"
                                              arguments:@[] error:&err_info];
	if (err_info) {
		NSLog(@"%@", [err_info description]);
	}
}

CFStringNormalizationForm UnicodeNormalizationForm()
{
	NSInteger unf = [[NSUserDefaults standardUserDefaults] integerForKey:@"UnicodeNormalizationIndex"];
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
        self.finderSelectionController = [[OSAScript alloc] initWithCompiledData:data
                                                        fromURL:nil
                                    usingStorageOptions:OSADontSetScriptLocation
                                                                      error:&error];
		self.hasNewNames = NO;
		normalizationForm = UnicodeNormalizationForm();
    }
    return self;
}

#pragma mark public
- (void)clearTargets
{
	[self setTargetDicts:nil];
	self.hasNewNames = NO;
}

#pragma mark method for static mode
- (void)clearNewNames
{
	if (!_targetDicts) return;
	for (RenameItem *item in _targetDicts) {
		item.nuName = nil;
	}
	self.hasNewNames = NO;
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
	NSArray *array = [_targetDicts valueForKey:@"hfsPath"];
	NSDictionary *err_info = nil;
	[_finderSelectionController executeHandlerWithName:@"select_items"
											arguments:@[array] error:&err_info];
	
	if (err_info) {
		NSString *msg = [NSString stringWithFormat:@"AppleScript Error : %@ (%@)",
						 err_info[OSAScriptErrorMessage],
						 err_info[OSAScriptErrorNumber]];
		NSDictionary *udict = @{NSLocalizedDescriptionKey: msg};
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
		NSDictionary *udict = @{NSLocalizedDescriptionKey: msg};
		*error = [NSError errorWithDomain:@"PowerRenamerError" code:3 userInfo:udict];
		return NO;
	}
	
	NSMutableArray *matchitems = [NSMutableArray arrayWithCapacity:[_targetDicts count]];
	NSRegularExpressionOptions opts = 0;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"IgnoreCases"]) {
		opts = opts | NSRegularExpressionCaseInsensitive;
	}
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:old_text
                                                                           options:opts
                                                                             error:error];
    if (*error) return NO;
	for (RenameItem *item in _targetDicts) {
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
		NSDictionary *udict = @{NSLocalizedDescriptionKey: msg};
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
    [invocation retainArguments];
	[invocation setSelector:selector];
	[invocation setArgument:&old_text atIndex:2];
	[invocation setArgument:&compopt atIndex:3];
	
	NSMutableArray *matchitems = [NSMutableArray arrayWithCapacity:[_targetDicts count]];
	for (RenameItem *item in _targetDicts) {
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
		NSDictionary *udict = @{NSLocalizedDescriptionKey: msg};
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
    [invocation retainArguments];
	[invocation setSelector:selector];
	[invocation setArgument:&old_text atIndex:2];
	[invocation setArgument:&new_text atIndex:3];
	[invocation setArgument:&opt atIndex:4];
	
	NSMutableArray *renamed_items = [NSMutableArray array];
	NSMutableDictionary *newnames_dict = [NSMutableDictionary dictionary];
	for (RenameItem *item in _targetDicts) {
		NSString *oldname = [item oldName];
		NSMutableString *newname = [oldname mutableCopy];
		[invocation setTarget:newname];
		[invocation invoke];
		NSUInteger result = 0;
		[invocation getReturnValue:&result];
		if (result && ![newname isEqualToString:oldname]) {
			NSString *dirpath = [[item posixPath] stringByDeletingLastPathComponent];
			NSMutableArray *newnames_indir = newnames_dict[dirpath];
			newname = [[newname uniqueNameAtLocation:dirpath
									   excepting:newnames_indir] mutableCopy];
			if (!newnames_indir) {
				newnames_indir = [NSMutableArray array];
			}
			[newnames_indir addObject:newname];
			item.nuName = newname;
			[renamed_items addObject:item];
		} else {
			item.nuName = newname;
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
			unsigned long len = [_targetDicts count] + (n-1);
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
	for (RenameItem *item in _targetDicts) {
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
			NSMutableArray *newnames_indir = newnames_dict[dirpath];
			newname = [[newname uniqueNameAtLocation:dirpath
										   excepting:newnames_indir] mutableCopy];
			if (!newnames_indir) {
				newnames_indir = [NSMutableArray array];
			}
			[newnames_indir addObject:newname];
			item.nuName = newname;
			[renamed_items addObject:item];
		} else {
			item.nuName = newname;
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
	self.hasNewNames = result;
	return result;
}

- (BOOL)resolveIcons
{
	[_targetDicts makeObjectsPerformSelector:@selector(resolveIcon)];
	return YES;
}

- (BOOL)resolveTargetItemsWithSorting:(BOOL)sortFlag error:(NSError **)error
{
	NSDictionary *err_info = nil;
	NSAppleEventDescriptor *script_result = nil;
	if (sortFlag) {
		script_result = [_finderSelectionController executeHandlerWithName:@"sorted_finderselection"
																arguments:@[] error:&err_info];
	} else {
		script_result = [_finderSelectionController executeHandlerWithName:@"get_finderselection_as_posix_path"
																arguments:@[] error:&err_info];
	}
	BOOL result = NO;
	if (err_info) {
#if useLog
		NSLog([err_info description]);
#endif
		NSString *msg = [NSString stringWithFormat:@"AppleScript Error : %@ (%@)",
										err_info[OSAScriptErrorMessage],
										 err_info[OSAScriptErrorNumber]];
		NSDictionary *udict = @{NSLocalizedDescriptionKey: msg};
		*error = [NSError errorWithDomain:@"PowerRenamerError" code:1 userInfo:udict];

		return result;
	}
	NSInteger nfile = [script_result numberOfItems];
	if (!nfile) {
		NSDictionary *udict = @{NSLocalizedDescriptionKey: NSLocalizedString(@"NoSelection", @"")};
		*error = [NSError errorWithDomain:@"PowerRenamerError" code:2 userInfo:udict];
		return result;
	}
	NSMutableArray *target_dicts = [NSMutableArray arrayWithCapacity:nfile];
	for (unsigned int i=1; i <= nfile; i++) {
		NSString *path = [[script_result descriptorAtIndex:i] stringValue];
		RenameItem *rename_item = [RenameItem renameItemWithPath:path normalization:normalizationForm];
		[target_dicts addObject:rename_item];
	}
	result = YES;
	[self setTargetDicts:target_dicts];
    self.isSorted = sortFlag;
	return result;
}

// sort to rename from subitems
- (NSArray *)sortedRenameItems
{
    NSSortDescriptor *sort_desc = [NSSortDescriptor
                                   sortDescriptorWithKey:@"self.posixPath" ascending:NO];
    return [_renamedItems sortedArrayUsingDescriptors:@[sort_desc]];
}

- (BOOL)applyNewNamesAndReturnError:(NSError **)error // rename with NSFileManager
{
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL result = NO;
    for (RenameItem *ritem in [self sortedRenameItems]) {
		NSString *src = [ritem posixPath];
		NSString *dest = [[src stringByDeletingLastPathComponent]
						  stringByAppendingPathComponent:ritem.nuName];
		result = [fm moveItemAtPath:src toPath:dest error:error];
#if useLog
        NSLog(@"source path: %@", src);
        NSLog(@"dest path: %@", dest);
        if (!result) NSLog(@"error: %@", *error);
#endif
		if (!result) break;
	}
	
	return result;
}

- (BOOL)processRenameAndReturnError:(NSError **)error // rename with Finder
{
    NSArray *sorted_array = [self sortedRenameItems];
    NSArray *paths = [sorted_array valueForKey:@"posixPath"];
	NSArray *newnames = [sorted_array valueForKey:@"nuName"];
	NSDictionary *err_info = nil;
#if useLog
    NSLog(@"%@", @"start rename");
#endif
    [_finderSelectionController executeHandlerWithName:@"process_rename_posix_paths"
                    arguments:@[paths, newnames]
                                                error:&err_info];
#if useLog
    NSLog(@"%@", @"end rename");
#endif
	if (err_info) {
#if useLog
		NSLog(@"error: %@", [err_info description]);
#endif
		NSString *msg = [NSString stringWithFormat:@"AppleScript Error : %@ (%@)",
						 err_info[OSAScriptErrorMessage],
						 err_info[OSAScriptErrorNumber]];
		NSDictionary *udict = @{NSLocalizedDescriptionKey: msg};
		*error = [NSError errorWithDomain:@"PowerRenamerError" code:2 userInfo:udict];		
		
		return NO;
	}

	return YES;
}

#pragma mark Accessors
- (void)setTargetDicts:(NSArray *)array
{
	if (_hasNewNames && _isSorted) {
		[self clearNewNames];
	}
    if (_targetDicts != array) {
        _targetDicts = nil;
        _targetDicts = array;
    }
}

@end
