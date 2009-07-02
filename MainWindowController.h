#import <Cocoa/Cocoa.h>
#import "PaletteWindowController.h"
#import "RenameEngine.h"

@interface MainWindowController : PaletteWindowController {
	IBOutlet id previewDrawer;
	IBOutlet id renameListController;
	RenameEngine *renameEngine;
}

- (IBAction)preview:(id)sender;
- (void)setRenameEngine:(RenameEngine *)engine;
- (IBAction)cancelAction:(id)sender;
- (IBAction)okAction:(id)sender;

@end
