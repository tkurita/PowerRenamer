#import "AltActionButton.h"

@implementation AltActionButton

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        isAltButton = NO;
    }
    return self;
}

- (void) setAltButton:(BOOL)flag
{
	isAltButton = flag;
}

- (BOOL)performKeyEquivalent:(NSEvent *)anEvent
{
	if (!isAltButton) return [super performKeyEquivalent:anEvent];
	if (![[anEvent charactersIgnoringModifiers] isEqualToString:@"\r"]) return NO;
	if (!([anEvent modifierFlags] & NSShiftKeyMask)) return NO;
	[self performClick:self];
	return YES;
}

@end
