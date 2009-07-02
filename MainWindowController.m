#import "MainWindowController.h"

@implementation MainWindowController

- (void)dealloc
{
	[renameEngine release];
	[super dealloc];
}

- (IBAction)preview:(id)sender
{
	RenameEngine *rename_engine = [[RenameEngine new] autorelease];
	NSError *error;
	[self setRenameEngine:rename_engine];
	[rename_engine resolveTargetItemsAndReturnError:&error];
	[rename_engine resolveNewNames];
	[rename_engine resolveIcons];
	[previewDrawer open:self];
}

- (IBAction)cancelAction:(id)sender
{
	[self close];
}

- (IBAction)okAction:(id)sender
{
	if (!renameEngine) {
		RenameEngine *rename_engine = [[RenameEngine new] autorelease];
		NSError *error;
		[self setRenameEngine:rename_engine];
		[rename_engine resolveTargetItemsAndReturnError:&error];
		[rename_engine resolveNewNames];
	}
	[renameEngine processRename];
	[previewDrawer close:self];
	[self setRenameEngine:nil];
	NSUserDefaults *userdefaults = [NSUserDefaults standardUserDefaults];
	if ([userdefaults boolForKey:@"AutoQuit"]) {
		[self close];
	}
}

- (void)setRenameEngine:(RenameEngine *)engine
{
	[engine retain];
	[renameEngine autorelease];
	renameEngine = engine;
}

@end
