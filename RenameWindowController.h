#import <Cocoa/Cocoa.h>
#import "PaletteWindowController.h"
#import "RenameEngine.h"

@interface RenameWindowController : PaletteWindowController {
	IBOutlet id previewDrawer;
	RenameEngine *renameEngine;
}

- (IBAction)preview:(id)sender;
- (void)setRenameEngine:(RenameEngine *)engine;
- (IBAction)cancelAction:(id)sender;
- (IBAction)okAction:(id)sender;

@end
