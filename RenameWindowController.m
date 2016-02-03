#import "RenameWindowController.h"
#import "AltActionButton.h"
#import "FrontAppMonitor.h"
#import "DNDArrayControllerDataTypesProtocol.h"
#import "PreferencesWindowController.h"

#define useLog 0

static NSMutableArray *reservedNumbers = nil;

@implementation RenameWindowController
@synthesize oldText = _oldText;
@synthesize newText = _newText;
@synthesize modeIndex = _modeIndex;
@synthesize startingNumber = _startingNumber;
@synthesize leadingZeros = _leadingZeros;

+(void)initialize
{
	if (!reservedNumbers) {
		reservedNumbers = [NSMutableArray new];
	}
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
	if (aSelector == @selector(closePreview:)) {
		return ([previewDrawer state] == NSDrawerOpenState);
	}
	return [super respondsToSelector:aSelector];
}

#pragma mark private
- (void)frontAppChanged:(NSNotification *)notification
{
	if (!_isStaticMode) [previewDrawer close];
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
	if (_oldText && (![_oldText isEqualToString:@""])) {
		if (![oldtext_history containsObject:_oldText]) {
			oldtext_history = [oldtext_history mutableCopy];
			[oldtext_history insertObject:_oldText atIndex:0];
			if ([oldtext_history count] > hist_max) {
				[oldtext_history removeLastObject];
			}
			[user_defaults setObject:oldtext_history forKey:@"OldTextHistory"];
		}
	}
	
	if ( _newText && (![_newText isEqualToString:@""])) {
		if (![newtext_history containsObject:_newText]) {
			newtext_history = [newtext_history mutableCopy];
			[newtext_history insertObject:_newText atIndex:0];
			if ([newtext_history count] > hist_max) {
				[newtext_history removeLastObject];
			}
			[user_defaults setObject:newtext_history forKey:@"NewTextHistory"];
		}
	}
}


- (void)setupToolbar
{
	NSToolbar *toolbar=[[NSToolbar alloc] initWithIdentifier:@"myToolbar"];
	toolbarItems=[NSMutableDictionary dictionary];
	
	[toolbar setDelegate:self];
	[toolbar setAllowsUserCustomization:YES];
	[toolbar setAutosavesConfiguration: YES];
	[toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
	[[self window] setToolbar:toolbar];
}

- (void)didChangedSettings
{
	if ([renameEngine hasNewNames]) {
		[renameEngine clearNewNames];
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
	self.isStaticMode = YES;
	[previewDrawer open:self];
}

#pragma mark toolbar

NSToolbarItem *addToolbarItem(NSMutableDictionary *theDict, NSString *identifier, NSString *label, NSString *paletteLabel, NSString *toolTip,
							  id target,SEL settingSelector, id itemContent,SEL action, NSMenu * menu)
{
    NSMenuItem *mItem;
    // here we create the NSToolbarItem and setup its attributes in line with the parameters
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:identifier];
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
		mItem=[[NSMenuItem alloc] init];
		[mItem setSubmenu: menu];
		[mItem setTitle: [menu title]];
		[item setMenuFormRepresentation:mItem];
    }
    // Now that we've setup all the settings for this new toolbar item, we add it to the dictionary.
    // The dictionary retains the toolbar item for us, which is why we could autorelease it when we created
    // it (above).
    [theDict setObject:item forKey:identifier];
	return item;
}

- (NSToolbarItem *)resolveToolbarItem:(NSString *)identifier
{
#if useLog
	NSLog(@"start resolveToolBar for %@", identifier);
#endif
	NSToolbarItem *toolbar_item = [toolbarItems objectForKey:identifier];
	if (toolbar_item) {
		return toolbar_item;
	}
	
	NSString *label;
	NSString *tool_tip;
	if ([identifier isEqualToString:@"Presets"]) {
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
		toolbar_item = addToolbarItem(toolbarItems, identifier, label, label, tool_tip,
						self,@selector(setView:), presetPullDownView, NULL,NULL);		
	} else if ([identifier isEqualToString:@"AddToPresets"]) {
		label = NSLocalizedString(@"Add to Presets", @"Toolbar's label for AddToPresets");
		tool_tip = NSLocalizedString(@"Save current settings as a preset", @"Toolbar's tool tip for AddToPresets");
		toolbar_item = addToolbarItem(toolbarItems, identifier, label, label, tool_tip,
									  self,@selector(setImage:),[NSImage imageNamed:@"plus24.png"],
									  @selector(addToPreset:),NULL);		
	} else if ([identifier isEqualToString:@"Preferences"]) {
		label = NSLocalizedString(@"Preferences", @"Toolbar's label for Preferences");
		tool_tip = NSLocalizedString(@"Open a preferences window", @"Toolbar's tool tip for Preferences");
		toolbar_item = addToolbarItem(toolbarItems, identifier, label, label, tool_tip,
									  self,@selector(setImage:),[NSImage imageNamed:NSImageNamePreferencesGeneral],
									  @selector(showPreferencesWindow:),NULL);				
	} else if ([identifier isEqualToString:@"Help"]) {
		label = NSLocalizedString(@"Help", @"Toolbar's label for Help");
		tool_tip = NSLocalizedString(@"Show PowerRenamer Help", @"Toolbar's tool tip for Help");			
		toolbar_item = addToolbarItem(toolbarItems, identifier, label, label, tool_tip,
					   self,@selector(setView:), helpButtonView, NULL, NULL);
	}
	
	return toolbar_item;
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    // We create and autorelease a new NSToolbarItem, and then go through the process of setting up its
    // attributes from the master toolbar item matching that identifier in our dictionary of items.
    NSToolbarItem *newItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    //NSToolbarItem *item=[toolbarItems objectForKey:itemIdentifier];
    NSToolbarItem *item = [self resolveToolbarItem:itemIdentifier];
	
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
	return [NSArray arrayWithObjects:@"Presets",@"AddToPresets", NSToolbarFlexibleSpaceItemIdentifier,
			@"Preferences", @"Help",nil];
}

// This method is required of NSToolbar delegates.  It returns an array holding identifiers for all allowed
// toolbar items in this toolbar.  Any not listed here will not be available in the customization palette.
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
	return [NSArray arrayWithObjects:@"Presets", @"AddToPresets", @"Help", @"Preferences",
			NSToolbarSeparatorItemIdentifier, NSToolbarSpaceItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier,
			NSToolbarCustomizeToolbarItemIdentifier, nil];
}


- (void)sheetDidEnd:(NSWindow*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo
{
    [sheet orderOut:self];
    
	if (returnCode != NSOKButton) return;
	
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:_oldText, @"search",
						  _newText, @"replace", [NSNumber numberWithInt:_modeIndex], @"mode",
						  _startingNumber, @"startingNumber", [NSNumber numberWithBool:_leadingZeros], @"leadingZeros",
						  _nuPresetName, @"name", nil];
	[presetsController addObject:dict];
}

#pragma mark Actions for toolbar
- (IBAction)showPreferencesWindow:(id)sender
{
	PreferencesWindowController *prefwin = [PreferencesWindowController sharedPreferencesWindow];
	[prefwin showWindow:self];
}

#pragma mark Actions
- (IBAction)closePreview:(id)sender
{
	[previewDrawer close];
}

- (IBAction)narrowDown:(id)sender
{
	self.isWorking = YES;
	[progressIndicator setHidden:NO];
	[progressIndicator startAnimation:self];

	NSError *error = nil;
	if (![renameEngine targetDicts]) {
		if (![renameEngine resolveTargetItemsWithSorting:NO error:&error]) {
			goto bail;
		}
	}
	if (![renameEngine narrowDownTargetItems:self error:&error]) {
		goto bail;
	}
	if (!_isStaticMode) {
		if ([[renameEngine targetDicts] count]) {
			[renameEngine selectInFinderReturningError:&error];
			if([previewDrawer state] == NSDrawerClosedState) 
				[renameEngine clearTargets];
		} else {
			[previewDrawer close];
			[renameEngine clearTargets];
		}
	}

bail:
	[progressIndicator setHidden:YES];
	[progressIndicator stopAnimation:self];

	if (error)
		[self presentError:error modalForWindow:[self window] delegate:nil didPresentSelector:nil contextInfo:nil];
	self.isWorking = NO;
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
	self.isWorking = YES;
	[progressIndicator setHidden:NO];
	[progressIndicator startAnimation:self];

	NSError *error = nil;
	if (![renameEngine targetDicts]) {
		if (![renameEngine resolveTargetItemsWithSorting:(_modeIndex == kNumberingMode) error:&error]) {
			[self presentError:error modalForWindow:[self window] delegate:nil 
												didPresentSelector:nil contextInfo:nil];
			goto bail;
		}
		[renameEngine resolveIcons];
	}
	if (![renameEngine resolveNewNames:self error:&error]) {
		[self presentError:error modalForWindow:[self window] delegate:nil didPresentSelector:nil contextInfo:nil];
		goto bail;
	}
	[previewDrawer open:self];
	[self saveHistory];

bail:	
	[progressIndicator setHidden:YES];
	[progressIndicator stopAnimation:self];
	self.isWorking = NO;
}

- (IBAction)cancelAction:(id)sender
{
	[self close];
}

- (IBAction)okAction:(id)sender
{
#if useLog
	NSLog(@"start okAction");
#endif	
	self.isWorking = YES;
	[progressIndicator setHidden:NO];
	[progressIndicator startAnimation:self];
	NSError *error = nil;
#if useLog
	NSLog(@"Getting Finder's selection");
#endif	
	if (![renameEngine hasNewNames]) {
		if ([renameEngine resolveTargetItemsWithSorting:(self.modeIndex == kNumberingMode) error:&error]) {
			[renameEngine resolveNewNames:self error:&error];
		}
		if (error) {
			[self presentError:error modalForWindow:[self window] delegate:nil didPresentSelector:nil contextInfo:nil];
			goto bail;
		}
	}
    {
	NSUserDefaults *userdefaults = [NSUserDefaults standardUserDefaults];
	BOOL result;
	if ([userdefaults boolForKey:@"RenameWithFinder"]) {
#if useLog
		NSLog(@"start renaiming with Finder");
#endif		
		result = [renameEngine processRenameAndReturnError:&error]; // rename with Finder
	} else {
#if useLog
		NSLog(@"start renaiming with NSFileManager");
#endif				
		result = [renameEngine applyNewNamesAndReturnError:&error]; // rename with NSFileManager
	}
	if (!result) {
		NSLog(@"%@", @"Error occurs during renaming.");
		if (error) {
			[self presentError:error modalForWindow:[self window] delegate:nil didPresentSelector:nil contextInfo:nil];
		}
		goto bail;
	}
	
	if ([userdefaults boolForKey:@"AutoQuit"]) {
		[self close];
	} else {
		[previewDrawer close:self];
		[self saveHistory];
		self.isStaticMode = NO;
		[renameEngine clearTargets];
	}}
bail:
	[progressIndicator setHidden:YES];
	[progressIndicator stopAnimation:self];
	self.isWorking = NO;
#if useLog	
	NSLog(@"end ok action");
#endif	
}


#pragma mark DNDArrayControlerDataTypesProtocol
- (NSArray*) additionalDataTypes
{
	return [NSArray arrayWithObject:NSFilenamesPboardType];
}

- (void)writeObjects:(NSArray *)targets toPasteboard:(NSPasteboard *)pboard
{
	[pboard setPropertyList:[targets valueForKey:@"posixPath"] forType:NSFilenamesPboardType];
}

- (NSArray *)newObjectsFromPasteboard:(NSPasteboard *)pboard
{
	if (![pboard availableTypeFromArray:
		  [NSArray arrayWithObjects:NSFilenamesPboardType, nil]]) {
		return nil;
	}
	
	NSArray *pathes = [pboard propertyListForType:NSFilenamesPboardType];
	RenameEngine *engine = [RenameEngine new];
	[engine setTargetFiles:pathes];
	[engine resolveIcons];
	NSError *error = nil;
	if ([renameEngine hasNewNames]) {
		if (![engine resolveNewNames:self error:&error]) {
			NSLog(@"%@", [error description]);
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
	[super windowWillClose:notification];
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	[user_defaults setObject:_oldText forKey:@"LastOldText"];
	[user_defaults setObject:_newText forKey:@"LastNewText"];
	[user_defaults setInteger:_modeIndex	forKey:@"ModeIndex"];
	[user_defaults setObject:_startingNumber forKey:@"StartingNumber"];
	[user_defaults setBool:_leadingZeros	forKey:@"LeadingZeros"];
	[self saveHistory];
	[user_defaults synchronize];
	[reservedNumbers removeObject:idNumber];
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize
{
	CGFloat max_height = [[self window] maxSize].height;
	if (frameSize.height > max_height) frameSize.height = max_height;
	return frameSize;
}

- (void)drawerWillClose:(NSNotification *)notification
{
	[previewDrawer setContentSize:[previewDrawer minContentSize]];
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
	NSSize current_size = [sender contentSize];
	NSSize win_content_size = [[[sender parentWindow] contentView] frame].size;
#if useLog	
	NSSize win_size = [[sender parentWindow] frame].size;
	NSLog(@"win_size : width=%f, height=%f", win_size.width, win_size.height);
	NSLog(@"win_content_size : width=%f, height=%f", win_content_size.width, win_content_size.height);
	NSLog(@"proposed : width=%f, height=%f", contentSize.width, contentSize.height);
#endif
	if (win_content_size.height-35 >= current_size.height) {
		return contentSize;
	}
	
	return [sender contentSize]; // prohibit resizing drawer.
	//return contentSize;
}

#pragma mark Accessors


- (void)setOldText:(NSString *)aText
{
	if (![_oldText isEqualToString:aText]) {
		[self didChangedSettings];
	}
    if (_oldText != aText) {
        _oldText = nil;
        _oldText = aText;
    }
}

- (NSString *)oldText
{
	if (_oldText)
		return _oldText;
	else
		return @"";
}

- (void)setNuText:(NSString *)aText
{
	if (![_newText isEqualToString:aText]) {
		[self didChangedSettings];
	}
    if (_newText != aText) {
        _newText = nil;
        _newText = aText;
    }
}

- (NSString *)newText
{
	if (_newText)
		return _newText;
	else
		return @"";
}

- (void)setModeIndex:(unsigned int)index
{
	if (_modeIndex != index) {
		[self didChangedSettings];
	}	
	_modeIndex = index;
}

- (void)setStartingNumber:(NSNumber *)num
{
	if (![_startingNumber isEqual:num]) {
		[self didChangedSettings];
	}
    if (_startingNumber != num) {
        _startingNumber = nil;
        _startingNumber = num;
    }
}

- (void)setLeadingZeros:(BOOL)flag
{
	if (_leadingZeros != flag) {
		[self didChangedSettings];
	}
	_leadingZeros = flag;
}

#pragma mark init

- (void)dealloc
{
#if useLog
	NSLog(@"start dealloc of RenameWindowController");
#endif
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.UseFloatingWindow"];
#if useLog
	NSLog(@"end dealloc of RenameWindowController");
#endif		
}

- (void)awakeFromNib
{
	self.nuPresetName = @"New Preset";
	
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
	
	[progressIndicator setHidden:YES];
	self.isWorking = NO;
}

@end
