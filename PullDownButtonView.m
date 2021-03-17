//
//  PullDownButtonView.m
//  PowerRenamer
//
//  Created by 栗田 哲郎 on 2021/03/17.
//

#import "PullDownButtonView.h"

@implementation PullDownButtonView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
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
}

@end
