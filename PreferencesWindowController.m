#import "PreferencesWindowController.h"

@implementation PreferencesWindowController
static PreferencesWindowController* sharedPrefWindow = nil;
static NSString *frameName = @"PreferencesWindow";

+ (PreferencesWindowController *)sharedPreferencesWindow
{
	if (!sharedPrefWindow) {
		sharedPrefWindow = [[self alloc] initWithWindowNibName:@"PreferencesWindow"];
	}
	return sharedPrefWindow;
}

- (IBAction)insertNewPreset:(id)sender
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"New Preset", @"name",
								 @"", @"replace", @"", @"search", @1, @"mode",
								 @1, @"startingNumber", 
								 @YES, @"leadingZeros", nil];
	[presetsArrayController insertObject:dict atArrangedObjectIndex:[presetsArrayController selectionIndex]+1];
	[presetsArrayController setSelectedObjects:@[dict]];
}

- (void)windowDidLoad
{
	[super windowDidLoad];
}

- (void)awakeFromNib
{
	NSWindow *a_window = [self window];
	[a_window center];
	[a_window setFrameUsingName:frameName];	
}

-(void)windowWillClose:(NSNotification *)notification
{
	[[self window] saveFrameUsingName:frameName];
	if (self == sharedPrefWindow) {
		sharedPrefWindow = nil;
	}
}

@end
