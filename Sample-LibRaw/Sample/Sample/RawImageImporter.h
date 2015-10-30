#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface RawImagerImporter : NSObject

+(NSImage *)getUIImageFromFile:(NSString*)file;
+(NSImage *)getThumbnailFromFile:(NSString*)file;
+(BOOL)writeRawData:(NSString *)file toDisk:(NSString *)destFile;
+(BOOL)writeThumbData:(NSString *)file toDisk:(NSString *)destFile;


+(void)log:(int)res str:(NSString *)str;
@end