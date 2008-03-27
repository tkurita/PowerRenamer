#import "AppController.h"
#import "StringExtra.h"
#import "DonationReminder/DonationReminder.h"

#define useLog 0

@implementation AppController
- (IBAction)makeDonation:(id)sender
{
	[DonationReminder goToDonation];
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

- (NSString *)regexReplace:(NSString *)sourceString withPattern:(NSString *)aPattern withString:(NSString *)aString
{
	NSString *result = nil;
	@try {
		result = [sourceString replaceForPattern:(NSString *)aPattern
										withString:(NSString *)aString];
	}
	@catch (NSException *exception) {
		//NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
		NSAlert *alert = [NSAlert alertWithMessageText:@"Reqular Expression Error" 
							defaultButton:@"OK" alternateButton:nil otherButton:nil 
							informativeTextWithFormat:[exception reason]];
		[alert beginSheetModalForWindow:mainWindow modalDelegate:nil
									didEndSelector:nil contextInfo:nil];
	}
	
	return result;
}
@end
