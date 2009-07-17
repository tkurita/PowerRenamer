#import <Cocoa/Cocoa.h>

@interface AppController : NSObject {
	IBOutlet id mainWindow;
	//IBOutlet id windowController;
	IBOutlet id prefernecesWindow;
}

- (IBAction)makeDonation:(id)sender;
- (IBAction)showPreferencesWindow:(id)sender;

@end
