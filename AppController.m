#import "AppController.h"
#import "DonationReminder/DonationReminder.h"
#import "WindowVisibilityController.h"
#import "RenameWindowController.h"
#import "AddDummyAtFirstTransformer.h"
#import "PreferencesWindowController.h"
#import "ModeIndexTransformer.h"
#import "ModeIsNotNumberingTransfomer.h"

#define useLog 0

@implementation AppController

+ (void)initialize
{	
	NSValueTransformer *transformer = [[AddDummyAtFirstTransformer new] autorelease];
	[NSValueTransformer setValueTransformer:transformer forName:@"AddDummyAtFirst"];
	transformer = [[ModeIndexTransformer new] autorelease];
	[NSValueTransformer setValueTransformer:transformer forName:@"ModeIndexToName"];
	transformer = [[ModeIsNotNumberingTransfomer new] autorelease];
	[NSValueTransformer setValueTransformer:transformer forName:@"ModeIsNotNumbering"];
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
	
	RenameWindowController *a_window = [[RenameWindowController alloc] initWithWindowNibName:@"RenameWindow"];
	[a_window showWindow:self];
	[a_window setUpForFiles:filenames];
	[NSApp activateIgnoringOtherApps:YES];
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
	RenameWindowController *a_window = [[RenameWindowController alloc] initWithWindowNibName:@"RenameWindow"];
	[a_window showWindow:self];
	[a_window setUpForFiles:filenames];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return ([theApplication isActive]);
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
	[NSApp setServicesProvider:self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"applicationDidFinishLaunching");
#endif
	[DonationReminder remindDonation];
	RenameWindowController *a_window = [[RenameWindowController alloc] initWithWindowNibName:@"RenameWindow"];
	[a_window showWindow:self];
	//[self showPreferencesWindow:self];
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
