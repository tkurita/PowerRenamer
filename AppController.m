#import "AppController.h"
#import "DonationReminder/DonationReminder.h"
#import "RenameWindowController.h"
#import "AddDummyAtFirstTransformer.h"
#import "PreferencesWindowController.h"
#import "ModeIndexTransformer.h"
#import "ModeIsNotNumberingTransfomer.h"
#import "RenameWindowController.h"
#import "WindowVisibilityController.h"

#define useLog 0

@implementation AppController

+ (void)initialize
{	
	if ( self == [AppController class]) {
		NSValueTransformer *transformer = [AddDummyAtFirstTransformer new];
		[NSValueTransformer setValueTransformer:transformer forName:@"AddDummyAtFirst"];
		transformer = [ModeIndexTransformer new];
		[NSValueTransformer setValueTransformer:transformer forName:@"ModeIndexToName"];
		transformer = [ModeIsNotNumberingTransfomer new];
		[NSValueTransformer setValueTransformer:transformer forName:@"ModeIsNotNumbering"];
	}
}

- (int)judgeVisibilityForApp:(NSDictionary *)appDict
{
#if useLog
	NSLog(@"start judgeVisibilityForApp");
	NSLog([appDict description]);
#endif
	if ([[[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:@"values.UseFloatingWindow"] boolValue]) {
		return kShouldPostController;
	} 
	return kShouldShow;
}

#pragma mark actions
- (IBAction)openRenamerWindow:(id)sender
{
	RenameWindowController *a_window = [[RenameWindowController alloc] initWithWindowNibName:@"RenameWindow"];
	[a_window showWindow:self];
}


- (IBAction)showPreferencesWindow:(id)sender
{
	PreferencesWindowController *prefwin = [PreferencesWindowController sharedPreferencesWindow];
	[prefwin showWindow:self];
}

- (IBAction)makeDonation:(id)sender
{
	[DonationReminder goToDonation];
}

#pragma mark delegate methods
- (void)renamerFromPasteboard:(NSPasteboard *)pboard userData:(NSString *)data error:(NSString **)error
{
#if useLog
	NSLog(@"start renamerFromPasteboard");
#endif
	NSArray *types = [pboard types];
	NSArray *filenames;
	if (![types containsObject:NSFilenamesPboardType] 
		|| !(filenames = [pboard propertyListForType:NSFilenamesPboardType])) {
        *error = NSLocalizedString(@"Error: Pasteboard doesn't contain file paths.",
								   @"Pasteboard couldn't give string.");
        return;
    }
	
	[self application:NSApp openFiles:filenames];
	[NSApp activateIgnoringOtherApps:YES];
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
	NSArray *windows = [NSApp orderedWindows];
	NSEnumerator *enumerator = [windows objectEnumerator];
	id a_window;
	RenameWindowController *wincotroller = nil;
	while (a_window = [enumerator nextObject]) {
		id wc = [a_window windowController];
		if ([wc isKindOfClass:[RenameWindowController class]]) {
			if (![wc isStaticMode]) wincotroller = wc;
			break;
		}
	}
	if (!wincotroller) {
		wincotroller = [[RenameWindowController alloc] initWithWindowNibName:@"RenameWindow"];
	}
	[wincotroller showWindow:self];
	[wincotroller setUpForFiles:filenames];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	if (!([theApplication isActive] && [[NSUserDefaults standardUserDefaults] boolForKey:@"QuitAfterClosingLastWindow"])) {
		return NO;
	}
	
	NSArray *windows = [NSApp windows];
	if (! windows) return YES;
	
	BOOL result = YES;
	NSEnumerator *enumerator = [windows objectEnumerator];
	NSWindow *a_window;
	while (a_window = [enumerator nextObject]) {
		RenameWindowController* wcontroller = [a_window windowController];
		if (wcontroller) {
			if ([wcontroller respondsToSelector:@selector(isWorking)] && [wcontroller isWorking]) {
				result = NO;
				break;
			}
		}
	}
	
	return result;
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"start applicationDidBecomeActive");
#endif
	id wc = [RenameWindowController frontmostWindowController];
	if (!wc) {
		RenameWindowController *a_window = [[RenameWindowController alloc] initWithWindowNibName:@"RenameWindow"];
		[a_window showWindow:self];
	}
#if useLog
	NSLog(@"end applicationDidBecomeActive");
#endif	
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"start applicationWillFinishLaunching");
#endif
	
	NSString *defaults_plist = [[NSBundle mainBundle] pathForResource:@"FactorySettings" ofType:@"plist"];
	NSDictionary *factory_defaults = [NSDictionary dictionaryWithContentsOfFile:defaults_plist];
	
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	[user_defaults registerDefaults:factory_defaults];
	[NSApp setServicesProvider:self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"applicationDidFinishLaunching");
#endif
	[DonationReminder remindDonation];
}

- (void)awakeFromNib
{
#if useLog
	NSLog(@"awakeFromNib");
#endif	
	 WindowVisibilityController *wv = [[WindowVisibilityController alloc] init];
	[wv setDelegate:self];
	[wv setVisibilityForCurrentApplication:kShouldShow];
	[PaletteWindowController setVisibilityController:wv];
}

@end
