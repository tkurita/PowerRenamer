#import "AppController.h"
#import "StringExtra.h"
#import "DonationReminder/DonationReminder.h"
#import "PaletteWindowController.h"
#import "WindowVisibilityController.h"
#import "RegexKitLite.h"
#import "RenameWindowController.h"

#define useLog 0

@implementation AppController

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

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return ([theApplication isActive]);
}

- (IBAction)showPreferencesWindow:(id)sender
{
	[prefernecesWindow orderFront:self];
	[prefernecesWindow makeMainWindow];
	[prefernecesWindow makeKeyWindow];
}

- (IBAction)makeDonation:(id)sender
{
	[DonationReminder goToDonation];
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"start applicationDidBecomeActive");
#endif
	if ([[NSApp windows] count] <= 1) {
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
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"applicationDidFinishLaunching");
#endif
	[DonationReminder remindDonation];
	RenameWindowController *a_window = [[RenameWindowController alloc] initWithWindowNibName:@"RenameWindow"];
	[a_window showWindow:self];
}

- (void)awakeFromNib
{
#if useLog
	NSLog(@"awakeFromNib");
#endif	
	 WindowVisibilityController *wv = [[[WindowVisibilityController alloc] init] autorelease];
	[wv setDelegate:self];
	[wv setVisibilityForCurrentApplication:kShouldShow];
	[PaletteWindowController setVisibilityController:wv];
}

@end
