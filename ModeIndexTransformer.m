#import "ModeIndexTransformer.h"


@implementation ModeIndexTransformer


+ (Class)transformedValueClass
{
	return [NSString class];
}


+ (BOOL)allowsReverseTransformation
{
	return NO;
}

- (id)transformedValue:(id)value
{
	int mode = [value intValue];
	NSString *mode_text = @"contain";
	switch (mode) {
		case 0:
			mode_text = @"contain";
			break;
		case 1:
			mode_text = @"starts with";
			break;
		case 2:
			mode_text = @"ends with";
			break;
		case 3:
			mode_text = @"regular expression";
			break;
		case 4:
			mode_text = @"numbering";
			break;
		default:
			break;
	}
	
	return NSLocalizedString(mode_text, @"");;
}

@end
