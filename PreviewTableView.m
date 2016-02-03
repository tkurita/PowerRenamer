#import "PreviewTableView.h"

#define useLog 0

@implementation PreviewTableView

- (BOOL)performKeyEquivalent:(NSEvent *)anEvent
{
#if useLog
	NSLog([anEvent description]);
#endif	
	if (([anEvent type] == NSKeyDown) && ([anEvent keyCode] == 51)) {
		[(NSArrayController *)[self delegate] remove:self];
		return YES;
	}
	return NO;
}

@end
