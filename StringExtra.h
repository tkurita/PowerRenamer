#import <Cocoa/Cocoa.h>

@interface NSString (StringExtra) 

-(BOOL) contain:(NSString *)containedText; 

-(NSMutableArray *) splitWithCharacterSet:(NSCharacterSet *)delimiters;

//- (NSString *)replaceForPattern:(NSString *)aPattern withString:(NSString *)aString;
// get file type from POSX path
// mainly called from AppleScript
-(NSString *)hfsFileType;

@end
