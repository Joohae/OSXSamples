#import <Foundation/Foundation.h>
#import "libraw.h"
#import "RawImageImporter.h"

/*
 convert libraw to NSImage works not fine :(
 */

@implementation RawImagerImporter

+(NSImage *)getUIImageFromFile:(NSString*)file
{
    LibRaw rawProcessor;
    
    rawProcessor.imgdata.params.half_size = 1;
    
    //open file
    int ret = rawProcessor.open_file([file UTF8String]);
    if (ret != LIBRAW_SUCCESS) return nil;

    // unpack
    [self log:ret str:@"File opening"];
    ret = rawProcessor.unpack();
    [self log:ret str:@"File unpacking"];
    if (ret != LIBRAW_SUCCESS) return nil;


    rawProcessor.imgdata.params.output_tiff = 1;
    rawProcessor.imgdata.params.use_camera_wb = 1;
    rawProcessor.imgdata.params.output_bps = 1;
    rawProcessor.dcraw_process();
//    rawProcessor.dcraw_ppm_tiff_writer([[NSString stringWithFormat:@"%@_testing.jpg", file] cStringUsingEncoding:NSUTF8StringEncoding]);


    int err;
    libraw_processed_image_t *imageData = rawProcessor.dcraw_make_mem_image(&err);
    rawProcessor.recycle();
    
    NSLog(@"\nColor %d \nbits %d \n %d data size \n %d height %d width",imageData->colors,imageData->bits,
          imageData->data_size,imageData->height,imageData->width);
    
    
    // make data provider from buffer
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, imageData->data, imageData->data_size, NULL);
    
    // set up for CGImage creation
    int bitsPerComponent = imageData->bits;
    int bitsPerPixel = imageData->bits * imageData->colors;
    int bytesPerRow  = imageData->bits * imageData->width;
    int width =imageData->width;
    int height = imageData->height;

    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault ;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    // make UIImage from CGImage
    NSImage *newUIImage = [[NSImage alloc] initWithCGImage:imageRef size:CGSizeMake(width, height)];
    LibRaw::dcraw_clear_mem(imageData);
    NSLog(@"%@",newUIImage);
    
    return newUIImage;
}

+(NSImage *)getThumbnailFromFile:(NSString*)file
{
    LibRaw rawProcessor;
    
    NSImage *retImage;
    
    //open file
    int ret = rawProcessor.open_file([file UTF8String]);
    if (ret != LIBRAW_SUCCESS) return nil;
    [self log:ret str:@"File opening"];
    
    
    NSLog(@"Raw Count %d",rawProcessor.imgdata.idata.raw_count);
    
    //unpack thumb only
    ret = rawProcessor.unpack_thumb();
    
    
    if (ret != LIBRAW_SUCCESS) {
        NSLog(@"Thumbnail not found for the raw image file");
    }
    
    [self log:ret str:@"File unpacking"];
    
    if (ret != LIBRAW_SUCCESS) return nil;
    
    libraw_thumbnail_t thumbnail = rawProcessor.imgdata.thumbnail;
    
    char *thumbData = thumbnail.thumb;
    
    NSLog(@"-----------Thumbnail Details-----------------");
    NSLog(@"Size width = %d    height = %d",thumbnail.twidth,thumbnail.theight);
    switch (thumbnail.tformat) {
        case LIBRAW_THUMBNAIL_UNKNOWN:
            NSLog(@"Format :Unknown Thumbnail");
            return nil;
            break;
        case LIBRAW_THUMBNAIL_JPEG:
            NSLog(@"Format:JPEG");
            retImage = [[NSImage alloc] initWithData:[NSData dataWithBytes:thumbData length:thumbnail.tlength]];
            rawProcessor.recycle();
            return retImage;
            break;
        case LIBRAW_THUMBNAIL_BITMAP:
            NSLog(@"Format:Bitmap");
            break;
            
        default:NSLog(@"Format Other :(We have not implemented)");
            return nil;
            break;
    }
    NSLog(@"Colors %d",thumbnail.tcolors);
    NSLog(@"---------------------------------------------\n\n");
    
    int err;
    
    libraw_processed_image_t *thumbbb = rawProcessor.dcraw_make_mem_thumb(&err);
    rawProcessor.recycle();
    
    NSLog(@"\nColor %d \nbits %d \n %d data size \n %d Length\n %d height %d width",thumbbb->colors,thumbbb->bits,
          thumbbb->data_size,thumbnail.tlength,thumbbb->height,thumbbb->width);
    
    
    // make data provider from buffer
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, thumbbb->data, thumbbb->data_size, NULL);
    
    // set up for CGImage creation
    int bitsPerComponent = 8;
    int bitsPerPixel = 24;
    int bytesPerRow = 3 * thumbbb->width;
    int width =thumbbb->width;
    int height = thumbbb->height;
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault ;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    
    // make UIImage from CGImage
    NSImage *newUIImage = [[NSImage alloc] initWithCGImage:imageRef size:CGSizeMake(width, height)];
    LibRaw::dcraw_clear_mem(thumbbb);
    return newUIImage;
}

+(BOOL)writeRawData:(NSString *)file toDisk:(NSString *)destFile
{
    LibRaw rawProcessor;
    
    //open file
    int ret = rawProcessor.open_file([file UTF8String]);
    if (ret != LIBRAW_SUCCESS) return NO;
    [self log:ret str:@"File opening"];
    
    //unpack
    ret = rawProcessor.unpack();
    ret = rawProcessor.unpack_thumb();
    
    if (ret != LIBRAW_SUCCESS) return NO;
    
    rawProcessor.imgdata.params.output_tiff = 1;
    rawProcessor.imgdata.params.use_camera_wb = 0;
    
    [self log:ret str:@"File unpacking"];
    
    // encode and write as tiff
    ret = rawProcessor.dcraw_process();
    
    [self log:ret str:@"dcraw_process"];
    
    if (ret != LIBRAW_SUCCESS) return NO;
    
    
    ret = rawProcessor.dcraw_ppm_tiff_writer([destFile UTF8String]);
    [self log:ret str:@"dcraw_ppm_tiff_writer"];
    
    if (ret != LIBRAW_SUCCESS) return NO;
    else return YES;
}

+(BOOL)writeThumbData:(NSString *)file toDisk:(NSString *)destFile
{
    LibRaw rawProcessor;
    
    //open file
    int ret = rawProcessor.open_file([file UTF8String]);
    if (ret != LIBRAW_SUCCESS) return NO;
    [self log:ret str:@"File opening"];
    
    //unpack
    ret = rawProcessor.unpack();
    ret = rawProcessor.unpack_thumb();
    
    if (ret != LIBRAW_SUCCESS) return NO;
    
    rawProcessor.imgdata.params.output_tiff = 1;
    rawProcessor.imgdata.params.use_camera_wb = 0;
    
    [self log:ret str:@"File unpacking"];
    
    // encode and write as tiff
    ret = rawProcessor.dcraw_process();
    
    [self log:ret str:@"dcraw_process"];
    
    if (ret != LIBRAW_SUCCESS) return NO;
    
    
    ret = rawProcessor.dcraw_thumb_writer([destFile UTF8String]);
    [self log:ret str:@"dcraw_thumb_writer"];
    
    if (ret != LIBRAW_SUCCESS) return NO;
    else return YES;
    
}
+(void)log:(int)res str:(NSString *)str
{
    if (res == LIBRAW_SUCCESS) {
        NSLog(@"%@ Successful",str);
    }
    else {
        NSLog(@"%@ Failed",str);
    }
    
}
@end