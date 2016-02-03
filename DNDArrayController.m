/* 
 Copyright (c) 2004-7, Apple Computer, Inc., all rights reserved.
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
 Apple Inc. ("Apple") in consideration of your agreement to the
 following terms, and your use, installation, modification or
 redistribution of this Apple software constitutes acceptance of these
 terms.  If you do not agree with these terms, please do not use,
 install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. 
 may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple.  Except
 as expressly stated in this notice, no other rights or licenses, express
 or implied, are granted by Apple herein, including but not limited to
 any patent rights that may be infringed by your derivative works or by
 other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2004-7 Apple Inc. All Rights Reserved.
 */
#include <AvailabilityMacros.h>
#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_5
#if __LP64__ || NS_BUILD_32_LIKE_64
typedef long NSInteger;
typedef unsigned long NSUInteger;
#else
typedef int NSInteger;
typedef unsigned int NSUInteger;
#endif
#endif


#import "DNDArrayController.h"

static NSString *MovedRowsType = @"MOVED_ROWS_TYPE";
static NSString *CopiedRowsType = @"COPIED_ROWS_TYPE";

/*
 Utility method to retrieve the number of indexes in a given range
 */
@interface NSIndexSet (CountOfIndexesInRange)
-(unsigned int)countOfIndexesInRange:(NSRange)range;
@end



@implementation DNDArrayController

static NSArray *internalDataTypes = nil;

+ (void)initialize
{
	if (!internalDataTypes) {
		internalDataTypes = [NSArray arrayWithObjects:CopiedRowsType, MovedRowsType, nil];
	}
}

- (void)awakeFromNib
{
    // register for drag and drop
    
	[tableView setDraggingSourceOperationMask:NSDragOperationLink forLocal:NO];
	[tableView setDraggingSourceOperationMask:(NSDragOperationCopy | NSDragOperationMove) forLocal:YES];
	
	NSArray *type_array = internalDataTypes;
	if (helperObject) {
		type_array = [type_array arrayByAddingObjectsFromArray:
							  [helperObject additionalDataTypes]];
	}
	[tableView registerForDraggedTypes:type_array];    
	[tableView setAllowsMultipleSelection:YES];
	
	[super awakeFromNib];
}



- (BOOL)tableView:(NSTableView *)aTableView
writeRowsWithIndexes:(NSIndexSet *)rowIndexes
	 toPasteboard:(NSPasteboard *)pboard
{
	
	/*
	 If the number of rows is not 1, then we only support our own types.
	 If there is just one row, then try to create an NSURL from the url
	 value in that row.  If that's possible, add NSURLPboardType to the
	 list of supported types, and add the NSURL to the pasteboard.
	 */
	[pboard declareTypes:internalDataTypes owner:self];
	if (helperObject) {
		// Try to create an URL
		// If we can, add NSURLPboardType to the declared types and write
		//the URL to the pasteboard; otherwise declare existing types
		NSArray *targets = [[self arrangedObjects] objectsAtIndexes:rowIndexes];
		NSArray *custom_types = [helperObject additionalDataTypes];
		[pboard addTypes:custom_types owner:self];
		[helperObject writeObjects:targets toPasteboard:pboard];
	}
	
    // add rows array for local move
	NSData *rowIndexesArchive = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard setData:rowIndexesArchive forType:MovedRowsType];
	
	// create new array of selected rows for remote drop
    // could do deferred provision, but keep it direct for clarity
	NSMutableArray *rowCopies = [NSMutableArray arrayWithCapacity:[rowIndexes count]];
	
    NSUInteger currentIndex = [rowIndexes firstIndex];
    while (currentIndex != NSNotFound)
    {
		[rowCopies addObject:[[self arrangedObjects] objectAtIndex:currentIndex]];
        currentIndex = [rowIndexes indexGreaterThanIndex: currentIndex];
    }
	
	// setPropertyList works here because we're using dictionaries, strings,
	// and dates; otherwise, archive collection to NSData...
	[pboard setPropertyList:rowCopies forType:CopiedRowsType];
	
    return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tv
					validateDrop:(id < NSDraggingInfo >)info 
					proposedRow:(int)row 
					proposedDropOperation:(NSTableViewDropOperation)operation
{
    
    NSDragOperation dragOp = NSDragOperationCopy;
    
    // if drag source is self, it's a move unless the Option key is pressed
    if ([info draggingSource] == tableView) {
		
		NSEvent *currentEvent = [NSApp currentEvent];
		int optionKeyPressed = [currentEvent modifierFlags] & NSAlternateKeyMask;
		if (optionKeyPressed == 0) {
			dragOp =  NSDragOperationMove;
		}
    }
    // we want to put the object at, not over,
    // the current row (contrast NSTableViewDropOn) 
    [tv setDropRow:row dropOperation:NSTableViewDropAbove];
	
    return dragOp;
}



- (BOOL)tableView:(NSTableView*)tv
	   acceptDrop:(id <NSDraggingInfo>)info
			  row:(int)row
	dropOperation:(NSTableViewDropOperation)op
{
    if (row < 0) {
		row = 0;
	}
	// if drag source is self, it's a move unless the Option key is pressed
    if ([info draggingSource] == tableView) {
		
		NSEvent *currentEvent = [NSApp currentEvent];
		int optionKeyPressed = [currentEvent modifierFlags] & NSAlternateKeyMask;
		
		if (optionKeyPressed == 0) {
			
			NSData *rowsData = [[info draggingPasteboard] dataForType:MovedRowsType];
			NSIndexSet *indexSet = [NSKeyedUnarchiver unarchiveObjectWithData:rowsData];
			
			NSIndexSet *destinationIndexes = [self moveObjectsInArrangedObjectsFromIndexes:indexSet toIndex:row];
			// set selected rows to those that were just moved
			[self setSelectionIndexes:destinationIndexes];
			
			return YES;
		}
    }
	
	// Can we get rows from another document?  If so, add them, then return.
	NSArray *newRows = [[info draggingPasteboard] propertyListForType:CopiedRowsType];
	
	if (newRows) {
		NSRange range = NSMakeRange(row, [newRows count]);
		NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
		
		[self insertObjects:newRows atArrangedObjectIndexes:indexSet];
		// set selected rows to those that were just copied
		[self setSelectionIndexes:indexSet];
		return YES;
    }
	
	if (helperObject) {
		NSArray *new_objects = [helperObject newObjectsFromPasteboard:[info draggingPasteboard]];
		if (new_objects) {
			NSRange range = NSMakeRange(row, [new_objects count]);
			NSIndexSet *index_set = [NSIndexSet indexSetWithIndexesInRange:range];
			[self insertObjects:new_objects atArrangedObjectIndexes:index_set];
			[self setSelectionIndexes:index_set];
		}
		return YES;		
	}
	
    return NO;
}



-(NSIndexSet *) moveObjectsInArrangedObjectsFromIndexes:(NSIndexSet*)fromIndexSet
												toIndex:(unsigned int)insertIndex
{	
	// If any of the removed objects come before the insertion index,
	// we need to decrement the index appropriately
	unsigned int adjustedInsertIndex =
	insertIndex - [fromIndexSet countOfIndexesInRange:(NSRange){0, insertIndex}];
	NSRange destinationRange = NSMakeRange(adjustedInsertIndex, [fromIndexSet count]);
	NSIndexSet *destinationIndexes = [NSIndexSet indexSetWithIndexesInRange:destinationRange];
	
	NSArray *objectsToMove = [[self arrangedObjects] objectsAtIndexes:fromIndexSet];
	[self removeObjectsAtArrangedObjectIndexes:fromIndexSet];	
	[self insertObjects:objectsToMove atArrangedObjectIndexes:destinationIndexes];
	
	return destinationIndexes;
}

#pragma mark data source of dable view
// required for Mac OS X 10.4
#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_5
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[self arrangedObjects] count];
}

- (id)tableView:(NSTableView *)aTableView 
		objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	id identifier = [aTableColumn identifier];
	return [[[self arrangedObjects] valueForKey:identifier] objectAtIndex:rowIndex];	
}
#endif
@end



/*
 Implementation of NSIndexSet utility category
 */
@implementation NSIndexSet (CountOfIndexesInRange)

-(NSUInteger)countOfIndexesInRange:(NSRange)range
{
	unsigned int start, end, count;
	
	if (range.length == 0)
	{
		return 0;	
	}
	
	start	= range.location;
	end		= start + range.length;
	count	= 0;
	
	NSUInteger currentIndex = [self indexGreaterThanOrEqualToIndex:start];
	
	while ((currentIndex != NSNotFound) && (currentIndex < end))
	{
		count++;
		currentIndex = [self indexGreaterThanIndex:currentIndex];
	}
	
	return count;
}
@end


