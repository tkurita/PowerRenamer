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
    
	NSInteger hist_max = [user_defaults integerForKey:@"HistoryMax"];
	if (_oldText && (![_oldText isEqualToString:@""])) {
		if (![oldtext_history containsObject:_oldText]) {
            if (oldtext_history) {
                oldtext_history = [oldtext_history mutableCopy];
            } else {
                oldtext_history = [NSMutableArray array];
            }
                
			[oldtext_history insertObject:_oldText atIndex:0];
			if ([oldtext_history count] > hist_max) {
				[oldtext_history removeLastObject];
			}
			[user_defaults setObject:oldtext_history forKey:@"OldTextHistory"];
		}
	}
	
	if ( _newText && (![_newText isEqualToString:@""])) {
		if (![newtext_history containsObject:_newText]) {
            if (newtext_history) {
                newtext_history = [newtext_history mutableCopy];
            } else {
                newtext_history = [NSMutableArray array];
            }
			[newtext_history insertObject:_newText atIndex:0];
			if ([newtext_history count] > hist_max) {
				[newtext_history removeLastObject];
			}
			[user_defaults setObject:newtext_history forKey:@"NewTextHistory"];
		}
	}
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

- (void)sheetDidEnd:(NSWindow*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo
{
    [sheet orderOut:self];
    
	if (returnCode != NSOKButton) return;
	
	NSDictionary *dict = @{@"search": _oldText,
						  @"replace": _newText, @"mode": [NSNumber numberWithInt:_modeIndex],
						  @"startingNumber": _startingNumber, @"leadingZeros": @(_leadingZeros),
						  @"name": _nuPresetName};
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
	NSDictionary *selected_presets = [presetsController arrangedObjects][[sender indexOfSelectedItem]-1];
	[self setOldText:selected_presets[@"search"]];
	[self setNewText:selected_presets[@"replace"]];
	[self setModeIndex:[selected_presets[@"mode"] intValue]];
	[self setStartingNumber:selected_presets[@"startingNumber"]];
	[self setLeadingZeros:[selected_presets[@"leadingZeros"] boolValue]];
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
	return @[NSFilenamesPboardType];
}

- (void)writeObjects:(NSArray *)targets toPasteboard:(NSPasteboard *)pboard
{
	[pboard setPropertyList:[targets valueForKey:@"posixPath"] forType:NSFilenamesPboardType];
}

- (NSArray *)newObjectsFromPasteboard:(NSPasteboard *)pboard
{
	if (![pboard availableTypeFromArray:
		  @[NSFilenamesPboardType]]) {
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
	[reservedNumbers removeObject:_idNumber];
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

- (void)setNewText:(NSString *)aText
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
	[self setModeIndex:(unsigned int)[user_defaults integerForKey:@"ModeIndex"]];
	[self setStartingNumber:[user_defaults objectForKey:@"StartingNumber"]];
	[self setLeadingZeros:[user_defaults boolForKey:@"LeadingZeros"]];
	[previewButton setAltButton:YES];
	[[FrontAppMonitor notificationCenter] addObserver:self selector:@selector(frontAppChanged:) 
												 name:@"FrontAppChangedNotification" object:nil];

    
	unsigned int n = 0;
	while (1) {
		NSNumber *num = [NSNumber numberWithInt:n];
		if (![reservedNumbers containsObject:num]) {
			[reservedNumbers addObject:num];
			self.idNumber = num;
			break;
		}
		n++;
	}
	if (n) [[self window] setTitle:[NSString stringWithFormat:@"%@ : %d", [[self window] title],n]];
	
	[progressIndicator setHidden:YES];
	self.isWorking = NO;
}

@end
