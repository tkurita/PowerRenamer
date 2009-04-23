#import "AppController.h"
#import "StringExtra.h"
#import "DonationReminder/DonationReminder.h"
#import "PaletteWindowController.h"
#import "WindowVisibilityController.h"
#import "RegexKitLite.h"

#define useLog 0

@implementation AppController

- (int)judgeVisibilityForApp:(NSDictionary *)appDict
{
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
	NSLog(@"applicationDidBecomeActive");
#endif
	[windowController showWindow:self];
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
	[windowController windowDidLoad];
	[windowController showWindow:self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"values.UseFloatingWindow"]) {
		NSUserDefaultsController *defaults_controller = [NSUserDefaultsController sharedUserDefaultsController];
		[windowController setUseFloating:[[defaults_controller valueForKeyPath:@"values.UseFloatingWindow"] boolValue]];
	}
}

- (void)awakeFromNib
{
#if useLog
	NSLog(@"awakeFromNib");
#endif	
	[windowController setFrameName:@"MainWindow"];
	
	NSUserDefaultsController *defaults_controller = [NSUserDefaultsController sharedUserDefaultsController];
	[windowController setUseFloating:[[defaults_controller valueForKeyPath:@"values.UseFloatingWindow"] boolValue]];
	[defaults_controller addObserver:self forKeyPath:@"values.UseFloatingWindow" 
							 options:NSKeyValueObservingOptionNew context:nil];
	WindowVisibilityController *wv = [[[WindowVisibilityController alloc] init] autorelease];
	[wv setDelegate:self];
	[PaletteWindowController setVisibilityController:wv];
	[windowController bindApplicationsFloatingOnForKey:@"applicationsFloatingOn"];
}


- (NSString *)regexReplace:(NSString *)sourceString withPattern:(NSString *)aPattern withString:(NSString *)aString
{
	NSString *result = nil;
	NSError *error = nil;
	sourceString = [sourceString normalizedString:kCFStringNormalizationFormKC];
	aPattern = [aPattern normalizedString:kCFStringNormalizationFormKC];
	aString = [aString normalizedString:kCFStringNormalizationFormKC];
	@try {
		result = [sourceString stringByReplacingOccurrencesOfRegex:(NSString *)aPattern 
														withString:(NSString *)aString
														   options:RKLNoOptions
															range:NSMakeRange(0, [sourceString length])
															 error:&error];
	}
	@catch (NSException *exception) {
		//NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
		NSAlert *alert = [NSAlert alertWithMessageText:@"Reqular Expression Error" 
							defaultButton:@"OK" alternateButton:nil otherButton:nil 
							informativeTextWithFormat:[exception reason]];
		[alert beginSheetModalForWindow:mainWindow modalDelegate:nil
									didEndSelector:nil contextInfo:nil];
	}
	
	if (error) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert beginSheetModalForWindow:mainWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
		result = nil;
	}
	
	return result;
}

@end
