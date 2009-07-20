
#import <Cocoa/Cocoa.h>


@interface PreferencesWindowController : NSWindowController {
	IBOutlet NSArrayController *presetsArrayController;
	NSIndexSet *selectedPresetIndexes;
}

+ (PreferencesWindowController *)sharedPreferencesWindow;
- (IBAction)insertNewPreset:(id)sender;

@end
