#import <Cocoa/Cocoa.h>
#import "PaletteWindowController.h"
#import "RenameEngine.h"
#import "RenameOptionsProtocol.h"

@interface RenameWindowController : PaletteWindowController<RenameOptionsProtocol> {
	IBOutlet id previewDrawer;
	IBOutlet id previewTable;
	RenameEngine *renameEngine;
	unsigned int modeIndex;
	NSString *oldText;
	NSString *newText;
}

#pragma mark Actions
- (IBAction)preview:(id)sender;
- (IBAction)cancelAction:(id)sender;
- (IBAction)okAction:(id)sender;

#pragma mark Accessors
- (void)setRenameEngine:(RenameEngine *)engine;
- (void)setOldText:(NSString *)aText;
- (void)setNewText:(NSString *)aText;
- (void)setModeIndex:(unsigned int)index;
@end
