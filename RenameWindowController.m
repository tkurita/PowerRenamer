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

- (IBAction)preview:(id)sender
{
	RenameEngine *rename_engine = [[RenameEngine new] autorelease];
	NSError *error;
	[self setRenameEngine:rename_engine];
	[rename_engine resolveTargetItemsAndReturnError:&error];
	[rename_engine resolveNewNames];
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
		[rename_engine resolveNewNames];
	}
	[renameEngine processRename];
	[previewDrawer close:self];
	[self setRenameEngine:nil];
	NSUserDefaults *userdefaults = [NSUserDefaults standardUserDefaults];
	if ([userdefaults boolForKey:@"AutoQuit"]) {
		[self close];
	}
}

- (void)setRenameEngine:(RenameEngine *)engine
{
	[engine retain];
	[renameEngine autorelease];
	renameEngine = engine;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"values.UseFloatingWindow"]) {
		NSUserDefaultsController *defaults_controller = [NSUserDefaultsController sharedUserDefaultsController];
		[self setUseFloating:[[defaults_controller valueForKeyPath:@"values.UseFloatingWindow"] boolValue]];
	}
}

- (void)awakeFromNib
{
	NSUserDefaultsController *defaults_controller = [NSUserDefaultsController sharedUserDefaultsController];
	[self setUseFloating:[[defaults_controller valueForKeyPath:@"values.UseFloatingWindow"] boolValue]];
	[defaults_controller addObserver:self forKeyPath:@"values.UseFloatingWindow" 
							 options:NSKeyValueObservingOptionNew context:nil];
	
	[self setFrameName:@"MainWindow"];
	[self bindApplicationsFloatingOnForKey:@"applicationsFloatingOn"];
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
