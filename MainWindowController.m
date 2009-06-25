#import "MainWindowController.h"
#import "RenameEngine.h"

@implementation MainWindowController

- (IBAction)preview:(id)sender
{
	RenameEngine *rename_engine = [RenameEngine new];
	NSError *error;
	[rename_engine resolveTargetItemsAndReturnError:&error];
	[rename_engine resolveNewNames];
	[previewDrawer open:self];
}
@end
