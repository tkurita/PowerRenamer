//
//  ToolbarController.m
//  PowerRenamer
//
//  Created by 栗田 哲郎 on 2016/02/04.
//
//

#import "ToolbarController.h"

#define useLog 0

@implementation ToolbarController

- (NSToolbarItem *)toolbarItemWithIdentifier:(NSString *)identifier
                                       label:(NSString *)label
                                 paleteLabel:(NSString *)paletteLabel
                                     toolTip:(NSString *)toolTip
                                      target:(id)target
                                 itemContent:(id)imageOrView
                                      action:(SEL)action
                                        menu:(NSMenu *)menu
{
    // here we create the NSToolbarItem and setup its attributes in line with the parameters
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:identifier];
    
    [item setLabel:label];
    [item setPaletteLabel:paletteLabel];
    [item setToolTip:toolTip];
    [item setTarget:target];
    [item setAction:action];
    
    // Set the right attribute, depending on if we were given an image or a view
    if([imageOrView isKindOfClass:[NSImage class]]){
        [item setImage:imageOrView];
    } else if ([imageOrView isKindOfClass:[NSView class]]){
        [item setView:imageOrView];
    }else {
        assert(!"Invalid itemContent: object");
    }
    
    
    // If this NSToolbarItem is supposed to have a menu "form representation" associated with it
    // (for text-only mode), we set it up here.  Actually, you have to hand an NSMenuItem
    // (not a complete NSMenu) to the toolbar item, so we create a dummy NSMenuItem that has our real
    // menu as a submenu.
    //
    if (menu != nil)
    {
        // we actually need an NSMenuItem here, so we construct one
        NSMenuItem *mItem = [NSMenuItem new];
        [mItem setSubmenu:menu];
        [mItem setTitle:label];
        [item setMenuFormRepresentation:mItem];
    }
    return item;
}

//It looks called for only toolbar items which is not defined in Nib.
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
                    itemForItemIdentifier:(NSString *)itemIdentifier
                    willBeInsertedIntoToolbar:(BOOL)flag
{
#if useLog
    NSLog(@"start toobar:itemForItemIdentifier:%@", itemIdentifier);
#endif
	NSToolbarItem *toolbar_item = _toolbarItems[itemIdentifier];
	if (toolbar_item) {
		return toolbar_item;
	}
	
	NSString *label;
	NSString *tool_tip;
	if ([itemIdentifier isEqualToString:@"Presets"]) {
		label = NSLocalizedString(@"Presets", @"Toolbar's label for presets");
		tool_tip = NSLocalizedString(@"Load a preset", @"Toolbar's tool tip for presets");
		[[settingsPullDownButton cell] setUsesItemFromMenu:NO];
		NSMenuItem *item = [[NSMenuItem allocWithZone:nil] initWithTitle:@"" action:NULL keyEquivalent:@""];
		NSImage *icon_image = [NSImage imageNamed:@"wizard32"];
		NSImage *arrow_image = [NSImage imageNamed:@"pulldown_arrow_small"];
		NSSize icon_size = [icon_image size];
		NSSize arrow_size = [arrow_image size];
		NSImage *popup_image = [[NSImage alloc] initWithSize: NSMakeSize(icon_size.width + arrow_size.width, icon_size.height)];
		
		NSRect icon_rect = NSMakeRect(0, 0, icon_size.width, icon_size.height);
		NSRect arrow_rect = NSMakeRect(0, 0, arrow_size.width, arrow_size.height);
		NSRect icon_drawrect = NSMakeRect(0, 0, icon_size.width, icon_size.height);
		NSRect arrow_drawrect = NSMakeRect(icon_size.width, 0, arrow_size.width, arrow_size.height);
		
		[popup_image lockFocus];
		[icon_image drawInRect: icon_drawrect  fromRect: icon_rect  operation: NSCompositeSourceOver  fraction: 1.0];
		[arrow_image drawInRect: arrow_drawrect  fromRect: arrow_rect  operation: NSCompositeSourceOver  fraction: 1.0];
		[popup_image unlockFocus];
		
		[item setImage:popup_image];
		[item setOnStateImage:nil];
		[item setMixedStateImage:nil];
		[[settingsPullDownButton cell] setMenuItem:item];
        toolbar_item = [self toolbarItemWithIdentifier:itemIdentifier
                                                 label:label
                                           paleteLabel:label
                                               toolTip:tool_tip
                                                target:actionTarget
                                           itemContent:presetPullDownView
                                                action:nil
                                                  menu:nil];
        
	} else if ([itemIdentifier isEqualToString:@"Help"]) {
		label = NSLocalizedString(@"Help", @"Toolbar's label for Help");
		tool_tip = NSLocalizedString(@"Show PowerRenamer Help", @"Toolbar's tool tip for Help");
        toolbar_item = [self toolbarItemWithIdentifier:itemIdentifier
                                                 label:label
                                           paleteLabel:label
                                               toolTip:tool_tip
                                                target:actionTarget
                                           itemContent:helpButtonView
                                                action:nil
                                                  menu:nil];
	}
	_toolbarItems[itemIdentifier] = toolbar_item;
	return toolbar_item;
}

// This method is required of NSToolbar delegates.  It returns an array holding identifiers for the default
// set of toolbar items.  It can also be called by the customization palette to display the default toolbar.
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
	return @[@"Presets",@"AddToPresets", NSToolbarFlexibleSpaceItemIdentifier,
          @"Preferences", @"Help"];
}

// This method is required of NSToolbar delegates.  It returns an array holding identifiers for all allowed
// toolbar items in this toolbar.  Any not listed here will not be available in the customization palette.
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
	return @[@"Presets", @"AddToPresets", @"Help", @"Preferences",
          NSToolbarSeparatorItemIdentifier, NSToolbarSpaceItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier,
          NSToolbarCustomizeToolbarItemIdentifier];
}


- (void) awakeFromNib
{
    self.toolbarItems=[NSMutableDictionary dictionary];
}
@end
