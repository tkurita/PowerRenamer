#import <Cocoa/Cocoa.h>
#import "PaletteWindowController.h"

@interface MainWindowController : PaletteWindowController {
	IBOutlet id previewDrawer;
}

- (IBAction)preview:(id)sender;

@end
