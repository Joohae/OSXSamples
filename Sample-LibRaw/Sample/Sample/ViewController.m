#import "ViewController.h"

#import "libraw.h"
#import "RawImageImporter.h"

@interface ViewController()
@property (weak) IBOutlet NSTextField *directoryPath;
@property (weak) IBOutlet NSTextField *messageBox;
@property (weak) IBOutlet NSImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    //[self extractThumbnailFromRawImage:@"/Users/famseedesigner1/Pictures/RAW_CANON_EOS_1DX.CR2"];

}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (IBAction)didOpenDirectoryClicked:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:NO];
    [_messageBox setStringValue:@"Selecting folder..."];
    
    
    if ([panel runModal] == NSOKButton) {
        NSArray *folder = [panel URLs];
        [_messageBox setStringValue:[folder[0] path]];
        [_directoryPath setStringValue:[folder[0] path]];
    }
}

- (IBAction)didExtractClicked:(id)sender {
    NSString *directoryPath = [_directoryPath stringValue];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *directoryUrl = [NSURL fileURLWithPath:directoryPath];
    
    NSArray *dirContents = [fileManager contentsOfDirectoryAtURL:directoryUrl
                                      includingPropertiesForKeys:@[]
                                                         options:NSDirectoryEnumerationSkipsHiddenFiles
                                                           error:nil];
    NSArray *targetExtension = @[@"CR2", @"CRW", @"NEF", @"ORF", @"RAF", @"DCR", @"DNG", @"MOS",
                                 @"cr2", @"crw", @"nef", @"orf", @"raf", @"dcr", @"dng", @"mos"
                                 ];
    NSPredicate *rawFileFilter = [NSPredicate predicateWithFormat:@"pathExtension IN[cd] %@", targetExtension];
    NSArray *onlyRawFiles = [dirContents filteredArrayUsingPredicate:rawFileFilter];
    
    for (NSURL *fileUrl in onlyRawFiles) {
        NSString *path = [fileUrl path];
        [self extractThumbnailFromRawImage:path];
        
//        NSImage *thumb = [RawImagerImporter getThumbnailFromFile:path];
//        [self saveAsJpeg:[NSString stringWithFormat:@"%@.thumb2.jpg", path] data:thumb];
//        _imageView.image = thumb;
        
//        NSImage *image = [RawImagerImporter getUIImageFromFile:path];
//        [self saveAsJpeg:[NSString stringWithFormat:@"%@.extract.jpg", path] data:image];
//        break;
    }
}

-(void)extractThumbnailFromRawImage:(NSString *)filePath {
    NSData *data;
    NSString *outputFile = [NSString stringWithFormat:@"%@.thumb.jpg", filePath];
    
    NSLog(@"Thumbnail of %@\n", filePath);
    data = [NSData dataWithContentsOfFile:filePath];
    
    libraw_data_t * cr2Data = libraw_init(0);
    libraw_open_file(cr2Data, [filePath UTF8String]);
    libraw_unpack_thumb(cr2Data);
    cr2Data->params.output_tiff = 1;
    cr2Data->params.use_camera_wb = 1;
    libraw_dcraw_thumb_writer(cr2Data, [outputFile UTF8String]);
    libraw_recycle(cr2Data);
}

-(void)saveAsJpeg:(NSString *)savePath data:(NSImage *)image {
    //  Compress and save cache file
    NSData *response = nil;
    float compression = 0.8; // COMPRESSION_RATIO would be 0.8
    NSBitmapImageRep * rep = [NSBitmapImageRep imageRepWithData:image.TIFFRepresentation];
    response = [rep representationUsingType:NSJPEGFileType
                                 properties:@{NSImageCompressionFactor:@(compression),
                                              NSImageProgressive:@NO
                                              }
                ];
    
   [response writeToFile:savePath atomically:NO];
}
@end
