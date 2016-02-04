//
//  ToolbarController.h
//  PowerRenamer
//
//  Created by 栗田 哲郎 on 2016/02/04.
//
//

#import <Cocoa/Cocoa.h>

@interface ToolbarController : NSObject <NSToolbarDelegate> {
    IBOutlet NSView *helpButtonView;
	IBOutlet NSView *presetPullDownView;
	IBOutlet id settingsPullDownButton;
    IBOutlet id actionTarget;
}

@property (nonatomic) NSMutableDictionary *toolbarItems;

@end
