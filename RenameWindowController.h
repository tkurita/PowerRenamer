#import <Cocoa/Cocoa.h>
#import "PaletteWindowController/PaletteWindowController.h"
#import "RenameEngine.h"
#import "RenameOptionsProtocol.h"

@interface RenameWindowController : PaletteWindowController<RenameOptionsProtocol> {
	IBOutlet id previewDrawer;
	IBOutlet NSTableView *previewTable;
	IBOutlet id previewButton;
	IBOutlet id presetsController;
	IBOutlet id newPresetNameWindow;
	IBOutlet RenameEngine *renameEngine;
	IBOutlet NSProgressIndicator *progressIndicator;
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
@property (nonatomic, strong) NSString *oldText;
@property (nonatomic, strong) NSString *newText;
@property (nonatomic) unsigned int modeIndex;
@property (nonatomic, strong) NSNumber *startingNumber;
@property (nonatomic, strong) NSString *nuPresetName;
@property (nonatomic) BOOL leadingZeros;
@property (nonatomic) BOOL isStaticMode;
@property (nonatomic) BOOL isWorking;
@property (nonatomic) NSNumber *idNumber;

//- (void)setOldText:(NSString *)aText;
//- (void)setNewText:(NSString *)aText;
//- (void)setModeIndex:(unsigned int)index;
//- (void)setStartingNumber:(NSNumber *)num;
//- (void)setNewPresetName:(NSString *)name;
//- (void)setLeadingZeros:(BOOL)flag;

#pragma mark public
+ (id)frontmostWindowController;
- (void)setUpForFiles:(NSArray *)filenames;

@end
