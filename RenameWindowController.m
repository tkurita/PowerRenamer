#import "RenameWindowController.h"
#import "AltActionButton.h"
#import "FrontAppMonitor.h"
#import "DNDArrayControllerDataTypesProtocol.h"

#define useLog 0

static NSMutableArray *reservedNumbers = nil;

@implementation RenameWindowController

+(void)initialize
{
	reservedNumbers = [NSMutableArray new];
}

#pragma mark private
- (void)frontAppChanged:(NSNotification *)notification
{
	if (!isStaticMode) [previewDrawer close];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"values.UseFloatingWindow"]) {
		NSUserDefaultsController *defaults_controller = [NSUserDefaultsController sharedUserDefaultsController];
		[self setUseFloating:[[defaults_controller valueForKeyPath:@"values.UseFloatingWindow"] boolValue]];
	}
}

- (void)saveHistory
{
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	NSMutableArray *oldtext_history = [user_defaults objectForKey:@"OldTextHistory"];
	NSMutableArray *newtext_history = [user_defaults objectForKey:@"NewTextHistory"];
	
	unsigned int hist_max = [user_defaults integerForKey:@"HistoryMax"];
	if ((oldText != nil) && (![oldText isEqualToString:@""])) {
		if (![oldtext_history containsObject:oldText]) {
			oldtext_history = [oldtext_history mutableCopy];
			[oldtext_history insertObject:oldText atIndex:0];
			if ([oldtext_history count] > hist_max) {
				[oldtext_history removeLastObject];
			}
			[user_defaults setObject:oldtext_history forKey:@"OldTextHistory"];
		}
	}
	
	if ((newText != nil)  && (![newText isEqualToString:@""])) {
		if (![newtext_history containsObject:newText]) {
			newtext_history = [newtext_history mutableCopy];
			[newtext_history insertObject:newText atIndex:0];
			if ([newtext_history count] > hist_max) {
				[newtext_history removeLastObject];
			}				
			[user_defaults setObject:newtext_history forKey:@"NewTextHistory"];
		}
	}
}

static void addToolbarItem(NSMutableDictionary *theDict, NSString *identifier, NSString *label, NSString *paletteLabel, NSString *toolTip,
						   id target,SEL settingSelector, id itemContent,SEL action, NSMenu * menu)
{
    NSMenuItem *mItem;
    // here we create the NSToolbarItem and setup its attributes in line with the parameters
    NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:identifier] autorelease];
    [item setLabel:label];
    [item setPaletteLabel:paletteLabel];
    [item setToolTip:toolTip];
    [item setTarget:target];
    // the settingSelector parameter can either be @selector(setView:) or @selector(setImage:).  Pass in the right
    // one depending upon whether your NSToolbarItem will have a custom view or an image, respectively
    // (in the itemContent parameter).  Then this next line will do the right thing automatically.
    [item performSelector:settingSelector withObject:itemContent];
    [item setAction:action];
    // If this NSToolbarItem is supposed to have a menu "form representation" associated with it (for text-only mode),
    // we set it up here.  Actually, you have to hand an NSMenuItem (not a complete NSMenu) to the toolbar item,
    // so we create a dummy NSMenuItem that has our real menu as a submenu.
    if (menu!=NULL)
    {
		// we actually need an NSMenuItem here, so we construct one
		mItem=[[[NSMenuItem alloc] init] autorelease];
		[mItem setSubmenu: menu];
		[mItem setTitle: [menu title]];
		[item setMenuFormRepresentation:mItem];
    }
    // Now that we've setup all the settings for this new toolbar item, we add it to the dictionary.
    // The dictionary retains the toolbar item for us, which is why we could autorelease it when we created
    // it (above).
    [theDict setObject:item forKey:identifier];
}

- (void)setupToolbar
{
	NSToolbar *toolbar=[[[NSToolbar alloc] initWithIdentifier:@"myToolbar"] autorelease];
	toolbarItems=[[NSMutableDictionary dictionary] retain];
	NSString *label;
	NSString *tool_tip;
	
	label = NSLocalizedString(@"Presets", @"Toolbar's label for presets");
	tool_tip = NSLocalizedString(@"Load a preset.", @"Toolbar's tool tip for presets");
	[[settingsPullDownButton cell] setUsesItemFromMenu:NO];
	NSMenuItem *item = [[NSMenuItem allocWithZone:[self zone]] initWithTitle:@"" action:NULL keyEquivalent:@""];
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
	
    [item setImage:[popup_image autorelease]];
    [item setOnStateImage:nil];
    [item setMixedStateImage:nil];
    [[settingsPullDownButton cell] setMenuItem:[item autorelease]];
	addToolbarItem(toolbarItems, @"Presets", label, label, tool_tip,
	self,@selector(setView:), presetPullDownView, NULL,NULL);
	
	label = NSLocalizedString(@"Add to Presets", @"Toolbar's label for AddToPresets");
	tool_tip = NSLocalizedString(@"Save current settings as a preset.", @"Toolbar's tool tip for AddToPresets");
	addToolbarItem(toolbarItems, @"AddToPresets", label, label, tool_tip,
				   self,@selector(setImage:),[NSImage imageNamed:@"plus24.png"],@selector(addToPreset:),NULL);
	
	label = NSLocalizedString(@"Help", @"Toolbar's label for Help");
	tool_tip = NSLocalizedString(@"Show PowerRenamer Help.", @"Toolbar's tool tip for Help");			
	addToolbarItem(toolbarItems,@"Help", label, label, tool_tip,
				   self,@selector(setView:), helpButtonView, NULL, NULL);
	
	[toolbar setDelegate:self];
	[toolbar setAllowsUserCustomization:YES];
	[toolbar setAutosavesConfiguration: YES];
	[toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
	[[self window] setToolbar:toolbar];
}

- (void)didChangedSettings
{
	if (isStaticMode) {
		[renameEngine clearNewNames];
	} else {
		[previewDrawer close];
	}
}

#pragma mark public
+ (id)frontmostWindowController
{
	NSArray *windows = [NSApp orderedWindows];
	NSEnumerator *enumerator = [windows objectEnumerator];
	id wincotroller = nil;
	NSWindow *a_window = nil;
	while (a_window = [enumerator nextObject]) {
		id wc = [a_window windowController];
		if ([wc isKindOfClass:[self class]]) {
			wincotroller = wc;
			break;
		}
	}
	return wincotroller;
}

- (void)setUpForFiles:(NSArray *)filenames
{
	[renameEngine setTargetFiles:filenames];
	[renameEngine resolveIcons];
	isStaticMode = YES;
	[previewDrawer open:self];
}

#pragma mark toolbar

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    // We create and autorelease a new NSToolbarItem, and then go through the process of setting up its
    // attributes from the master toolbar item matching that identifier in our dictionary of items.
    NSToolbarItem *newItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
    NSToolbarItem *item=[toolbarItems objectForKey:itemIdentifier];
    
    [newItem setLabel:[item label]];
    [newItem setPaletteLabel:[item paletteLabel]];
    if ([item view]!=NULL) {
		[newItem setView:[item view]];
    }
    else {
		[newItem setImage:[item image]];
    }
    [newItem setToolTip:[item toolTip]];
    [newItem setTarget:[item target]];
    [newItem setAction:[item action]];
    [newItem setMenuFormRepresentation:[item menuFormRepresentation]];
    // If we have a custom view, we *have* to set the min/max size - otherwise, it'll default to 0,0 and the custom
    // view won't show up at all!  This doesn't affect toolbar items with images, however.
    if ([newItem view]!=NULL) {
		[newItem setMinSize:[[item view] bounds].size];
		[newItem setMaxSize:[[item view] bounds].size];
    }
	
    return newItem;
}

// This method is required of NSToolbar delegates.  It returns an array holding identifiers for the default
// set of toolbar items.  It can also be called by the customization palette to display the default toolbar.    
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
	return [NSArray arrayWithObjects:@"Presets",@"AddToPresets", NSToolbarFlexibleSpaceItemIdentifier, @"Help",nil];
}

// This method is required of NSToolbar delegates.  It returns an array holding identifiers for all allowed
// toolbar items in this toolbar.  Any not listed here will not be available in the customization palette.
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
	return [NSArray arrayWithObjects:@"Presets", @"AddToPresets", @"Help",
			NSToolbarSeparatorItemIdentifier, NSToolbarSpaceItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier,NSToolbarCustomizeToolbarItemIdentifier, nil];
}


- (void)sheetDidEnd:(NSWindow*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo
{
    [sheet orderOut:self];
    
	if (returnCode != NSOKButton) return;
	
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:oldText, @"search",
						  newText, @"replace", [NSNumber numberWithInt:modeIndex], @"mode", 
						  startingNumber, @"startingNumber", [NSNumber numberWithBool:leadingZeros], @"leadingZeros",
						  newPresetName, @"name", nil];
	[presetsController addObject:dict];
}

#pragma mark Actions
- (IBAction)narrowDown:(id)sender
{
	NSError *error = nil;
	if (!isStaticMode) {
		if (![renameEngine resolveTargetItemsWithSorting:NO error:&error]) {
			goto bail;
		}
	}
	if (![renameEngine narrowDownTargetItems:self error:&error]) {
		[self presentError:error modalForWindow:[self window] delegate:nil didPresentSelector:nil contextInfo:nil];
		if (!isStaticMode) [renameEngine selectInFinderReturningError:&error];
	}

bail:
	if (error)
		[self presentError:error modalForWindow:[self window] delegate:nil didPresentSelector:nil contextInfo:nil];
}

- (IBAction)okNewPresetName:(id)sender
{
	[NSApp endSheet:[sender window] returnCode:NSOKButton];
}

- (IBAction)cancelNewPresetName:(id)sender
{
	[NSApp endSheet:[sender window] returnCode:NSCancelButton];
}


- (IBAction)addToPreset:(id)sender
{
	[NSApp beginSheet:newPresetNameWindow
			   modalForWindow:[self window] 
				modalDelegate:self 
			   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) 
				  contextInfo:nil];
}

- (IBAction)applyPreset:(id)sender
{
	NSDictionary *selected_presets = [[presetsController arrangedObjects] objectAtIndex: [sender indexOfSelectedItem]-1];
	[self setOldText:[selected_presets objectForKey:@"search"]];
	[self setNewText:[selected_presets objectForKey:@"replace"]];
	[self setModeIndex:[[selected_presets objectForKey:@"mode"] intValue]];
	[self setStartingNumber:[selected_presets objectForKey:@"startingNumber"]];
	[self setLeadingZeros:[[selected_presets objectForKey:@"leadingZeros"] boolValue]];
}

- (IBAction)preview:(id)sender
{
	/*
	if (!isStaticMode) {
		RenameEngine *rename_engine = [[RenameEngine new] autorelease];
		[self setRenameEngine:rename_engine];
	}
	 */
	NSError *error = nil;
	if (!isStaticMode) {
		if (![renameEngine resolveTargetItemsWithSorting:(modeIndex == kNumberingMode) error:&error]) {
			[self presentError:error modalForWindow:[self window] delegate:nil 
												didPresentSelector:nil contextInfo:nil];
			return;
		}
	}
	if (![renameEngine resolveNewNames:self error:&error]) {
		[self presentError:error modalForWindow:[self window] delegate:nil didPresentSelector:nil contextInfo:nil];
		return;
	}
	[renameEngine resolveIcons];
	[previewDrawer open:self];
	[self saveHistory];
}

- (IBAction)cancelAction:(id)sender
{
	[self close];
}

- (IBAction)okAction:(id)sender
{
	NSError *error = nil;
	
	if (![renameEngine hasNewNames]) {
		if ([renameEngine resolveTargetItemsWithSorting:(modeIndex == kNumberingMode) error:&error]) {
			[renameEngine resolveNewNames:self error:&error];
		}
		if (error) {
			[self presentError:error modalForWindow:[self window] delegate:nil didPresentSelector:nil contextInfo:nil];
			return;
		}
	}
	
	if (![renameEngine processRenameAndReturnError:&error]) {
		[self presentError:error modalForWindow:[self window] delegate:nil didPresentSelector:nil contextInfo:nil];
		return;
	}
	[previewDrawer close:self];
	NSUserDefaults *userdefaults = [NSUserDefaults standardUserDefaults];
	if ([userdefaults boolForKey:@"AutoQuit"]) {
		[self close];
	} else {
		[self saveHistory];
		isStaticMode = NO;
	}
}


#pragma mark DNDArrayControlerDataTypesProtocol
- (NSArray*) additionalDataTypes
{
	return [NSArray arrayWithObject:NSFilenamesPboardType];
}

- (void)writeObjects:(NSArray *)targets toPasteboard:(NSPasteboard *)pboard
{
	[pboard setPropertyList:[targets valueForKey:@"filePath"] forType:NSFilenamesPboardType];
}

- (NSArray *)newObjectsFromPasteboard:(NSPasteboard *)pboard
{
	if (![pboard availableTypeFromArray:
		  [NSArray arrayWithObjects:NSFilenamesPboardType, nil]]) {
		return nil;
	}
	
	NSArray *pathes = [pboard propertyListForType:NSFilenamesPboardType];
	RenameEngine *engine = [[RenameEngine new] autorelease];
	[engine setTargetFiles:pathes];
	[engine resolveIcons];
	NSError *error = nil;
	if ([renameEngine hasNewNames]) {
		if (![engine resolveNewNames:self error:&error]) {
			NSLog([error description]);
			return nil;
		}
	}
	
	return [engine targetDicts];
}

#pragma mark delegate methods
- (BOOL)windowShouldClose:(id)window
{
	[previewDrawer close]; // required to release targetDicts when closing window
	return YES;
}

-(void) windowWillClose:(NSNotification *)notification
{
	[[FrontAppMonitor notificationCenter] removeObserver:self];
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	[user_defaults setObject:oldText forKey:@"LastOldText"];
	[user_defaults setObject:newText forKey:@"LastNewText"];
	[user_defaults setInteger:modeIndex	forKey:@"ModeIndex"];
	[user_defaults setObject:startingNumber forKey:@"StartingNumber"];
	[user_defaults setBool:leadingZeros	forKey:@"LeadingZeros"];
	[self saveHistory];
	[user_defaults synchronize];
	[reservedNumbers removeObject:idNumber];
	[self autorelease];
}

- (void)drawerDidClose:(NSNotification *)notification
{
	[renameEngine clearTargets];
}

- (void)drawerDidOpen:(NSNotification *)notification
{
	NSSize spacing = [previewTable intercellSpacing];
	NSRect crect = [previewTable rectOfColumn:0];
	NSSize currentsize = [previewDrawer contentSize];
	NSRect hrect = [[previewTable headerView] headerRectOfColumn:0];
	currentsize.height = crect.size.height + hrect.size.height + spacing.height;
	NSSize maxsize = [previewDrawer maxContentSize];
	if (currentsize.height > maxsize.height) {
		currentsize.height = maxsize.height;
	} else {
		NSSize minsize = [previewDrawer minContentSize];
		if (currentsize.height < minsize.height) {
			currentsize.height = minsize.height;
		}
	}
	[previewDrawer setContentSize:currentsize];
}

- (NSSize)drawerWillResizeContents:(NSDrawer *)sender toSize:(NSSize)contentSize
{
	return [sender contentSize]; // prohibit resizing drawer.
	//return contentSize;
}

#pragma mark Accessors

- (void)setNewPresetName:(NSString *)name
{
	[name retain];
	[newPresetName autorelease];
	newPresetName = name;
}

- (void)setOldText:(NSString *)aText
{
	if (![oldText isEqualToString:aText]) {
		[self didChangedSettings];
	}
	[aText retain];
	[oldText autorelease];
	oldText = aText;
}

- (NSString *)oldText
{
	if (oldText)
		return oldText;
	else
		return @"";
}

- (void)setNewText:(NSString *)aText
{
	if (![newText isEqualToString:aText]) {
		[self didChangedSettings];
	}
	[aText retain];
	[newText autorelease];
	newText = aText;
}

- (NSString *)newText
{
	if (newText)
		return newText;
	else
		return @"";
}

- (void)setModeIndex:(unsigned int)index
{
	if (modeIndex != index) {
		[self didChangedSettings];
	}	
	modeIndex = index;
}

- (unsigned int)modeIndex
{
	return modeIndex;
}

- (void)setStartingNumber:(NSNumber *)num
{
	if (![startingNumber isEqual:num]) {
		[self didChangedSettings];
	}
	[num retain];
	[startingNumber autorelease];
	startingNumber = num;
}

- (NSNumber *)startingNumber
{
	return startingNumber;
}

- (void)setLeadingZeros:(BOOL)flag
{
	if (leadingZeros != flag) {
		[self didChangedSettings];
	}
	leadingZeros = flag;
}

- (BOOL)leadingZeros
{
	return leadingZeros;
}

- (BOOL)isStaticMode
{
	return isStaticMode;
}

#pragma mark init

- (void)dealloc
{
#if useLog
	NSLog(@"start dealloc of RenameWindowController");
#endif
	[toolbarItems release];
	//[renameEngine release];
	[idNumber release];
	[super dealloc];
#if useLog
	NSLog(@"end dealloc of RenameWindowController");
#endif		
}

- (void)awakeFromNib
{
	[self setNewPresetName:@"New Preset"];
	
	NSUserDefaultsController *defaults_controller = [NSUserDefaultsController sharedUserDefaultsController];
	[self setUseFloating:[[defaults_controller valueForKeyPath:@"values.UseFloatingWindow"] boolValue]];
	[defaults_controller addObserver:self forKeyPath:@"values.UseFloatingWindow" 
							 options:NSKeyValueObservingOptionNew context:nil];
	
	[self setFrameName:@"MainWindow"];
	[self bindApplicationsFloatingOnForKey:@"applicationsFloatingOn"];
	
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	[self setOldText:[user_defaults stringForKey:@"LastOldText"]];
	[self setNewText:[user_defaults stringForKey:@"LastNewText"]];
	[self setModeIndex:[user_defaults integerForKey:@"ModeIndex"]];
	[self setStartingNumber:[user_defaults objectForKey:@"StartingNumber"]];
	[self setLeadingZeros:[user_defaults boolForKey:@"LeadingZeros"]];
	[previewButton setAltButton:YES];
	[[FrontAppMonitor notificationCenter] addObserver:self selector:@selector(frontAppChanged:) 
												 name:@"FrontAppChangedNotification" object:nil];
	[self setupToolbar];
	
	unsigned int n = 0;
	while (1) {
		NSNumber *num = [NSNumber numberWithInt:n];
		if (![reservedNumbers containsObject:num]) {
			[reservedNumbers addObject:num];
			idNumber = num;
			break;
		}
		n++;
	}
	if (n) [[self window] setTitle:[NSString stringWithFormat:@"%@ : %d", [[self window] title],n]];
}

@end
