#import <Cocoa/Cocoa.h>
#import "PaletteWindowController.h"
#import "RenameEngine.h"
#import "RenameOptionsProtocol.h"

@interface RenameWindowController : PaletteWindowController<RenameOptionsProtocol> {
	IBOutlet id previewDrawer;
	IBOutlet id previewTable;
	IBOutlet id previewButton;
	IBOutlet NSView *helpButtonView;
	IBOutlet NSView *presetPullDownView;
	IBOutlet id settingsPullDownButton;
	IBOutlet id presetsController;
	IBOutlet id newPresetNameWindow;
	
	RenameEngine *renameEngine;
	unsigned int modeIndex;
	NSString *oldText;
	NSString *newText;
	NSMutableDictionary *toolbarItems;
	NSNumber *startingNumber;
	BOOL leadingZeros;
	NSString *newPresetName;
}

#pragma mark Actions
- (IBAction)preview:(id)sender;
- (IBAction)cancelAction:(id)sender;
- (IBAction)okAction:(id)sender;
- (IBAction)applyPreset:(id)sender;
- (IBAction)saveAsPreset:(id)sender;
- (IBAction)okNewPresetName:(id)sender;
- (IBAction)cancelNewPresetName:(id)sender;
- (IBAction)narrowDown:(id)sender;

#pragma mark Accessors
- (void)setRenameEngine:(RenameEngine *)engine;
- (void)setOldText:(NSString *)aText;
- (void)setNewText:(NSString *)aText;
- (void)setModeIndex:(unsigned int)index;
- (void)setStartingNumber:(NSNumber *)num;
- (void)setNewPresetName:(NSString *)name;
- (void)setLeadingZeros:(BOOL)flag;

@end
