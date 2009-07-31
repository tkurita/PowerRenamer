@protocol DNDArrayControllerDataTypesProtocol
- (NSArray*) additionalDataTypes;
- (void)writeObjects:(NSArray *)target toPasteboard:(NSPasteboard *)pboard;
- (NSArray *)newObjectsFromPasteboard:(NSPasteboard *)pboard;
@end
