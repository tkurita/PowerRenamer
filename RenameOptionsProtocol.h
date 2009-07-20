enum RenameMode {
	kContainMode = 0,
	kStartsWithMode = 1,
	kEndsWithMode = 2,
	kRegexMode = 3,
	kNumberingMode = 4
};

@protocol RenameOptionsProtocol
- (NSString *)oldText;
- (NSString *)newText;
- (unsigned int)modeIndex;
- (NSNumber *)startingNumber;
- (BOOL)leadingZeros;
@end