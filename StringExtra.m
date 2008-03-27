#import "StringExtra.h"
#import <OgreKit/OgreKit.h>

@implementation NSString (StringExtra)

- (NSString *)replaceForPattern:(NSString *)aPattern withString:(NSString *)aString
{
	OGRegularExpression  *regex;
	regex = [OGRegularExpression regularExpressionWithString:aPattern];
	return [regex replaceAllMatchesInString:self withString:aString];
}

- (NSMutableString *)normalizedString:(CFStringNormalizationForm) theForm
{
	NSMutableString *self_string = [[self mutableCopy] autorelease];
	CFStringNormalize((CFMutableStringRef) self_string,  theForm);
	return self_string;
}

- (BOOL)isEqualToNormalizedString:(NSString *)targetString
{
	NSMutableString *self_string = [[self mutableCopy] autorelease];
	NSMutableString *target_string = [[targetString mutableCopy] autorelease];
	CFStringNormalize((CFMutableStringRef) self_string,  kCFStringNormalizationFormKC);
	CFStringNormalize((CFMutableStringRef) target_string,  kCFStringNormalizationFormKC);
	return [self_string isEqualToString:target_string];
}

- (BOOL)contain:(NSString *)containedText
{
	NSRange theRange = [self rangeOfString:containedText];
	return (theRange.length != 0);
}

- (NSMutableArray *)splitWithCharacterSet:(NSCharacterSet *)delimiters
{
	NSMutableArray * wordArray = [NSMutableArray array];
	NSScanner *scanner = [NSScanner scannerWithString:self];
	NSString *scannedText;
    while(![scanner isAtEnd]) {
        if([scanner scanUpToCharactersFromSet:delimiters intoString:&scannedText]) {
			[wordArray addObject:scannedText];
        }
        [scanner scanCharactersFromSet:delimiters intoString:nil];
    }
	return wordArray;
}

- (NSString *)hfsFileType
{
	return NSHFSTypeOfFile(self);
}

@end
