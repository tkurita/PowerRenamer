#import "FilenameComboBox.h"

#define useLog 0

static NSArray *supportedTypes = nil;

@implementation FilenameComboBox

+ (void)initialize
{
	if (!supportedTypes) {
		supportedTypes = [[NSArray alloc] initWithObjects:NSFilenamesPboardType, NSStringPboardType, nil];
	}
}

- (void)awakeFromNib
{
#if useLog
	NSLog(@"awakeFromNib in FilenameComboBox");
#endif
	//NSArray* supported_types = [NSArray arrayWithObjects:NSFilenamesPboardType, NSStringPboardType, nil];
	// in future NSPasteboardTypeString instead of NSStringPboardType for Mac OS X 10.6 or later.
	[self registerForDraggedTypes:supportedTypes];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
#if useLog
	NSLog(@"draggingEntered in FilenameComboBox");
#endif
    NSPasteboard *pboard = [sender draggingPasteboard];
	
	int dragOperation = NSDragOperationNone;
	NSString *available_type = [pboard availableTypeFromArray:supportedTypes];
#if useLog
	NSLog(@"available_type : %@", available_type);
#endif	
    if (available_type) {
		dragOperation =  NSDragOperationCopy;
		if ([self currentEditor]) {
			[self abortEditing];
		}
	}

    return dragOperation;
}

- (BOOL)prepareForDragOperation:(id < NSDraggingInfo >)sender
{
#if useLog
	NSLog(@"prepareForDragOperation in FilenameComboBox");
#endif
	return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
#if useLog
	NSLog(@"performDragOperation in FilenameComboBox");
#endif
    NSPasteboard *pboard = [sender draggingPasteboard];
    BOOL didPerformDragOperation = NO;
	
	NSArray *filenames = [pboard propertyListForType:NSFilenamesPboardType];
#if useLog
    NSLog(@"performDragOperation: filenames: %@", [filenames description]);
#endif
	
    if (filenames && [filenames count]) {
		[self setStringValue:[[filenames lastObject] lastPathComponent]];
		didPerformDragOperation = YES;
		goto bail;
    } 
	{
	NSString *string = [pboard propertyListForType:NSStringPboardType];
	if (string) {
		[self setStringValue:string];
		didPerformDragOperation = YES;
    } 	
	}
bail:
	if (didPerformDragOperation) {
		NSDictionary *binding_info = [self infoForBinding: NSValueBinding];
		if (binding_info) {
			NSObject *bound_object = [binding_info valueForKey:NSObservedObjectKey];
			NSString *key_path = [binding_info valueForKey:NSObservedKeyPathKey];
			[bound_object setValue:[self stringValue] forKeyPath:key_path];
		}
	}
	return didPerformDragOperation;
}

@end
