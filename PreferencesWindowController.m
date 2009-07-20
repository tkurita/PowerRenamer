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
								 @"", @"replace", @"", @"search", [NSNumber numberWithInt:1], @"mode",
								 [NSNumber numberWithInt:1], @"startingNumber", 
								 [NSNumber numberWithBool:YES], @"leadingZeros", nil];
	[presetsArrayController insertObject:dict atArrangedObjectIndex:[presetsArrayController selectionIndex]+1];
	[presetsArrayController setSelectedObjects:[NSArray arrayWithObject:dict]];
}

- (void)windowDidLoad
{
	/*
	selectedPresetIndexes = [NSUnarchiver unarchiveObjectWithData:
								[[NSUserDefaults standardUserDefaults] objectForKey:@"SelectedPresetIndexes"]];
	NSLog([selectedPresetIndexes description]);
	[presetsArrayController setSelectionIndexes:selectedPresetIndexes];
	*/
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
	//NSData *data = [NSArchiver archivedDataWithRootObject:[presetsArrayController selectionIndexes]];
	//[[NSUserDefaults standardUserDefaults] setObject:data forKey:@"SelectedPresetIndexes"];
	if (self == sharedPrefWindow) {
		sharedPrefWindow = nil;
	}
	[self autorelease];
}

@end
