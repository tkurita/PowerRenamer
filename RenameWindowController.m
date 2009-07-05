#import "RenameWindowController.h"

#define useLog 1
@implementation RenameWindowController

- (void)dealloc
{
#if useLog
	NSLog(@"start dealloc of RenameWindowController");
#endif	
	[renameEngine release];
	[super dealloc];
#if useLog
	NSLog(@"end dealloc of RenameWindowController");
#endif		
}

- (void)awakeFromNib
{
	NSUserDefaultsController *defaults_controller = [NSUserDefaultsController sharedUserDefaultsController];
	[self setUseFloating:[[defaults_controller valueForKeyPath:@"values.UseFloatingWindow"] boolValue]];
	[defaults_controller addObserver:self forKeyPath:@"values.UseFloatingWindow" 
							 options:NSKeyValueObservingOptionNew context:nil];
	
	[self setFrameName:@"MainWindow"];
	[self bindApplicationsFloatingOnForKey:@"applicationsFloatingOn"];
	
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	[self setOldText:[user_defaults stringForKey:@"LastOldText"]];
	[self setNewText:[user_defaults stringForKey:@"LastNewText"]];
	[self setModeIndex:[user_defaults integerForKey:@"ModeIndex"]];	
}

#pragma mark private

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"values.UseFloatingWindow"]) {
		NSUserDefaultsController *defaults_controller = [NSUserDefaultsController sharedUserDefaultsController];
		[self setUseFloating:[[defaults_controller valueForKeyPath:@"values.UseFloatingWindow"] boolValue]];
	}
}

- (void)discardPreview
{
	[previewDrawer close];
	[self setRenameEngine:nil];
}

- (void)saveHistory
{
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	NSMutableArray *oldtext_history = [user_defaults objectForKey:@"OldTextHistory"];
	NSMutableArray *newtext_history = [user_defaults objectForKey:@"NewTextHistory"];
	
	unsigned int hist_max = [user_defaults integerForKey:@"HistoryMax"];
	if ((oldText != nil) && (![oldText isEqualToString:@""])) {
		if (![oldtext_history containsObject:oldText]) {
			oldtext_history = [oldtext_history mutableCopy];
			[oldtext_history insertObject:oldText atIndex:0];
			if ([oldtext_history count] > hist_max) {
				[oldtext_history removeLastObject];
			}
			[user_defaults setObject:oldtext_history forKey:@"OldTextHistory"];
		}
	}
	
	if ((newText != nil)  && (![newText isEqualToString:@""])) {
		if (![newtext_history containsObject:newText]) {
			newtext_history = [newtext_history mutableCopy];
			[newtext_history insertObject:newText atIndex:0];
			if ([newtext_history count] > hist_max) {
				[newtext_history removeLastObject];
			}				
			[user_defaults setObject:newtext_history forKey:@"NewTextHistory"];
		}
	}
}

#pragma mark Actions

- (IBAction)preview:(id)sender
{
	RenameEngine *rename_engine = [[RenameEngine new] autorelease];
	NSError *error = nil;
	[self setRenameEngine:rename_engine];
	if (![rename_engine resolveTargetItemsAndReturnError:&error]) {
		[self presentError:error modalForWindow:[self window] delegate:nil didPresentSelector:nil contextInfo:nil];
		return;
	}
	if (![rename_engine resolveNewNames:self error:&error]) {
		[self presentError:error modalForWindow:[self window] delegate:nil didPresentSelector:nil contextInfo:nil];
		return;
	}
	[rename_engine resolveIcons];
	[previewDrawer open:self];
	[self saveHistory];
}

- (IBAction)cancelAction:(id)sender
{
	[self close];
}

- (IBAction)okAction:(id)sender
{
	NSError *error = nil;
	if (!renameEngine) {
		RenameEngine *rename_engine = [[RenameEngine new] autorelease];
		[self setRenameEngine:rename_engine];
		if ([rename_engine resolveTargetItemsAndReturnError:&error]) {
			[rename_engine resolveNewNames:self error:&error];
		}
		if (error) {
			[self presentError:error modalForWindow:[self window] delegate:nil didPresentSelector:nil contextInfo:nil];
			return;
		}
	}
	if (![renameEngine processRenameAndReturnError:&error]) {
		[self presentError:error modalForWindow:[self window] delegate:nil didPresentSelector:nil contextInfo:nil];
		return;
	}
	[previewDrawer close:self];
	[self setRenameEngine:nil];
	NSUserDefaults *userdefaults = [NSUserDefaults standardUserDefaults];
	if ([userdefaults boolForKey:@"AutoQuit"]) {
		[self close];
	} else {
		[self saveHistory];
	}
}

#pragma mark delegate methods
-(void) windowWillClose:(NSNotification *)notification
{
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	[user_defaults setObject:oldText forKey:@"LastOldText"];
	[user_defaults setObject:newText forKey:@"LastNewText"];
	[user_defaults setInteger:modeIndex	forKey:@"ModeIndex"];
	[self saveHistory];
	[user_defaults synchronize];
	[self autorelease];
}

- (void)drawerDidOpen:(NSNotification *)notification
{
	//unsigned int nrows = [previewTable numberOfRows];
	//float rowheight = [previewTable rowHeight];
	NSSize spacing = [previewTable intercellSpacing];
	NSRect crect = [previewTable rectOfColumn:0];
	NSSize currentsize = [previewDrawer contentSize];
	NSRect hrect = [[previewTable headerView] headerRectOfColumn:0];
	currentsize.height = crect.size.height + hrect.size.height + spacing.height;
	NSSize maxsize = [previewDrawer maxContentSize];
	if (currentsize.height > maxsize.height) {
		currentsize.height = maxsize.height;
	} else {
		NSSize minsize = [previewDrawer minContentSize];
		if (currentsize.height < minsize.height) {
			currentsize.height = minsize.height;
		}
	}
	[previewDrawer setContentSize:currentsize];
}

- (NSSize)drawerWillResizeContents:(NSDrawer *)sender toSize:(NSSize)contentSize
{
	return [sender contentSize]; // prohibit resizing drawer.
}

#pragma mark Accessors

- (void)setRenameEngine:(RenameEngine *)engine
{
	[engine retain];
	[renameEngine autorelease];
	renameEngine = engine;
}

- (void)setOldText:(NSString *)aText
{
	if (![oldText isEqualToString:aText]) {
		[self discardPreview];
	}
	[aText retain];
	[oldText autorelease];
	oldText = aText;
}

- (NSString *)oldText
{
	return oldText;
}

- (void)setNewText:(NSString *)aText
{
	if (![newText isEqualToString:aText]) {
		[self discardPreview];
	}
	[aText retain];
	[newText autorelease];
	newText = aText;
}

- (NSString *)newText
{
	return newText;
}

- (void)setModeIndex:(unsigned int)index
{
	if (modeIndex != index) {
		[self discardPreview];
	}	
	modeIndex = index;
}

- (unsigned int)modeIndex
{
	return modeIndex;
}


//- (void)windowDidLoad
//{
//#if useLog
//	NSLog(@"start windowDidLoad");
//#endif	
//	NSWindow *a_window = [self window];
//	[a_window center];
//	[a_window setFrameUsingName:@"MainWindow"];
//	
//	NSUserDefaultsController *defaults_controller = [NSUserDefaultsController sharedUserDefaultsController];
//	[self setUseFloating:[[defaults_controller valueForKeyPath:@"values.UseFloatingWindow"] boolValue]];
//	[defaults_controller addObserver:self forKeyPath:@"values.UseFloatingWindow" 
//							 options:NSKeyValueObservingOptionNew context:nil];
//	/*
//	WindowVisibilityController *wv = [[[WindowVisibilityController alloc] init] autorelease];
//	[wv setDelegate:self];
//	[PaletteWindowController setVisibilityController:wv];
//	 */
//	[self bindApplicationsFloatingOnForKey:@"applicationsFloatingOn"];
//#if useLog
//	NSLog(@"end windowDidLoad");
//#endif	
//}

@end
