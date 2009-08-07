#import <Cocoa/Cocoa.h>
#import "PaletteWindowController.h"
#import "RenameEngine.h"
#import "RenameOptionsProtocol.h"

@interface RenameWindowController : PaletteWindowController<RenameOptionsProtocol> {
	IBOutlet id previewDrawer;
	IBOutlet NSTableView *previewTable;
	IBOutlet id previewButton;
	IBOutlet NSView *helpButtonView;
	IBOutlet NSView *presetPullDownView;
	IBOutlet id settingsPullDownButton;
	IBOutlet id presetsController;
	IBOutlet id newPresetNameWindow;
	IBOutlet RenameEngine *renameEngine;
	IBOutlet NSProgressIndicator *progressIndicator;
	
	unsigned int modeIndex;
	NSString *oldText;
	NSString *newText;
	NSMutableDictionary *toolbarItems;
	NSNumber *startingNumber;
	BOOL leadingZeros;
	NSString *newPresetName;
	BOOL isStaticMode;
	NSNumber *idNumber;
}

#pragma mark Actions
- (IBAction)preview:(id)sender;
- (IBAction)cancelAction:(id)sender;
- (IBAction)okAction:(id)sender;
- (IBAction)applyPreset:(id)sender;
- (IBAction)addToPreset:(id)sender;
- (IBAction)okNewPresetName:(id)sender;
- (IBAction)cancelNewPresetName:(id)sender;
- (IBAction)narrowDown:(id)sender;
- (IBAction)closePreview:(id)sender;

#pragma mark Accessors
- (void)setOldText:(NSString *)aText;
- (void)setNewText:(NSString *)aText;
- (void)setModeIndex:(unsigned int)index;
- (void)setStartingNumber:(NSNumber *)num;
- (void)setNewPresetName:(NSString *)name;
- (void)setLeadingZeros:(BOOL)flag;

#pragma mark public
+ (id)frontmostWindowController;
- (void)setUpForFiles:(NSArray *)filenames;
- (BOOL)isStaticMode;
@end
