#import "AddDummyAtFirstTransformer.h"


@implementation AddDummyAtFirstTransformer


+ (Class)transformedValueClass
{
	return [NSMutableArray class];
}


+ (BOOL)allowsReverseTransformation
{
	return YES;
}

- (id)transformedValue:(id)array
{
	array = [array mutableCopy];
	[array insertObject:@""	atIndex:0];
	return array;
}
		
- (id)reverseTransformedValue:(NSMutableArray *)array
{
	[array removeObjectAtIndex:0];
	return array;
}

@end
