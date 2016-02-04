#import <Cocoa/Cocoa.h>

@interface AppController : NSObject {
	IBOutlet id mainWindow;
	IBOutlet id prefernecesWindow;
}

- (IBAction)makeDonation:(id)sender;
- (IBAction)showPreferencesWindow:(id)sender;
- (IBAction)openRenamerWindow:(id)sender;

@end
