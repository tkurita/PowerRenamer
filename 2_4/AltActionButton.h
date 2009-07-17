#import <Cocoa/Cocoa.h>


@interface AltActionButton : NSButton {
	BOOL isAltButton;
}

- (void) setAltButton:(BOOL)flag;
@end
