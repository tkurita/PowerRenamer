#import "RenameEngine.h"

static NSAppleScript *getFinderSelection;

@implementation RenameEngine

+ (void)initialize
{
	NSString *path = [[NSBundle mainBundle] pathForResource:@"GetFinderSelection"
											ofType:@"scpt" inDirectory:@"Scripts"];
	NSDictionary *errInfo;
	getFinderSelection = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path]
																error:&errInfo];
}

- (void)replaceSubstring
{
	NSUserDefaults *userdefaults = [NSUserDefaults standardUserDefaults];
	NSString *old_text = [userdefaults stringForKey:@"LastOldText"];
	NSString *new_text = [userdefaults stringForKey:@"LastNewText"];
	int len = [targetItems count];
	NSMutableArray *old_names = [NSMutableArray arrayWithCapacity:len];
	NSMutableArray *new_names = [NSMutableArray arrayWithCapacity:len];
	for (unsigned int n = 1; n < len; n++) {
		NSString *path = [targetItems objectAtIndex:n];
		NSString *name = [path lastPathComponent];
		NSString *newname = [name stringByReplacingOccurrencesOfString:old_text withString:new_text];
		[old_names addObject:name];
		[new_names addObject:newname];
	}
}

- (BOOL)resolveNewNames
{
	int mode = [[NSUserDefaults standardUserDefaults] integerForKey:@"ModeIndex"];
	[self replaceSubstring];
	
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
		/*
		 NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"OK"];
		[alert setMessageText:
		 [NSString stringWithFormat:@"AppleScript Error : %@",[err_info objectForKey:NSAppleScriptErrorNumber]]
		 ];
		[alert setInformativeText:[err_info objectForKey:NSAppleScriptErrorMessage]];
		[alert setAlertStyle:NSWarningAlertStyle];
		if ([alert runModal] == NSAlertFirstButtonReturn) {
		} 
		[alert release];
		 */
		goto bail;
	}
	unsigned int nfile = [script_result numberOfItems];
	if (!nfile) {
		NSDictionary *udict = [NSDictionary dictionaryWithObject:NSLocalizedString(@"NoSelection", @"")
														  forKey:NSLocalizedDescriptionKey];
		*error = [NSError errorWithDomain:@"PowerRenamerError" code:2 userInfo:udict];
		goto bail;
	}
	NSMutableArray *files = [NSMutableArray arrayWithCapacity:nfile];
	for (unsigned int i=1; i <= nfile; i++) {
		[files addObject:[NSURL fileURLWithPath:[[script_result descriptorAtIndex:i] stringValue]]];
	}
	result = YES;
	[self setTargetItems:files];
bail:
	return result;
}

#pragma mark Accessors

- (NSArray *)targetItems
{
	return targetItems;
}

- (void)setTargetItems:(NSArray *)array
{
	[array retain];
	[targetItems autorelease];
	targetItems = array;
}

- (NSArray *)newNames
{
	return newNames;
}

- (void)setNewNames:(NSArray *)array
{
	[array retain];
	[newNames autorelease];
	newNames = array;
}

- (NSArray *)oldNames
{
	return oldNames;
}

- (void)setOldNames:(NSArray *)array
{
	[array retain];
	[oldNames autorelease];
	oldNames = array;
}

@end
