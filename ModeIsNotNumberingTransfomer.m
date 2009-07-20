#import "ModeIsNotNumberingTransfomer.h"


@implementation ModeIsNotNumberingTransfomer

+ (Class)transformedValueClass
{
	return [NSNumber class];
}


+ (BOOL)allowsReverseTransformation
{
	return NO;
}

- (id)transformedValue:(id)value
{
	int mode = [value intValue];
	return [NSNumber numberWithBool: mode != 4];
}

@end
