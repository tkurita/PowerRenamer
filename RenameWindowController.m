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

#pragma mark Actions

- (IBAction)preview:(id)sender
{
	RenameEngine *rename_engine = [[RenameEngine new] autorelease];
	NSError *error;
	[self setRenameEngine:rename_engine];
	[rename_engine resolveTargetItemsAndReturnError:&error];
	[rename_engine resolveNewNames:self];
	[rename_engine resolveIcons];
	[previewDrawer open:self];
}

- (IBAction)cancelAction:(id)sender
{
	[self close];
}

- (IBAction)okAction:(id)sender
{
	if (!renameEngine) {
		RenameEngine *rename_engine = [[RenameEngine new] autorelease];
		NSError *error;
		[self setRenameEngine:rename_engine];
		[rename_engine resolveTargetItemsAndReturnError:&error];
		[rename_engine resolveNewNames:self];
	}
	[renameEngine processRename];
	[previewDrawer close:self];
	[self setRenameEngine:nil];
	NSUserDefaults *userdefaults = [NSUserDefaults standardUserDefaults];
	if ([userdefaults boolForKey:@"AutoQuit"]) {
		[self close];
	}
}

#pragma mark delegate methods
-(void) windowWillClose:(NSNotification *)notification
{
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	[user_defaults setObject:oldText forKey:@"LastOldText"];
	[user_defaults setObject:newText forKey:@"LastNewText"];
	[user_defaults setInteger:modeIndex	forKey:@"ModeIndex"];
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
	modeIndex = index;
}

- (unsigned int)modeIndex
{
	return modeIndex;
}

#pragma mark private

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"values.UseFloatingWindow"]) {
		NSUserDefaultsController *defaults_controller = [NSUserDefaultsController sharedUserDefaultsController];
		[self setUseFloating:[[defaults_controller valueForKeyPath:@"values.UseFloatingWindow"] boolValue]];
	}
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
