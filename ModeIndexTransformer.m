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
	NSString *mode_text = nil;
	switch (mode) {
		case 0:
			mode_text = @"Contain";
			break;
		case 1:
			mode_text = @"Starts with";
			break;
		case 2:
			mode_text = @"Ends with";
			break;
		case 3:
			mode_text = @"Regular Expression";
			break;
		case 4:
			mode_text = @"Numbering";
			break;
		default:
			break;
	}
	
	return NSLocalizedString(mode_text, @"");;
}

@end
