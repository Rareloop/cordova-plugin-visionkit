#import "VisionKit.h"

#define RL_SCAN_PREFIX @"rl_scan_"

@implementation VisionKit

@synthesize documentCameraViewController;

- (void)scan:(CDVInvokedUrlCommand*)command {
    // NSString* myarg = [[command arguments] objectAtIndex:0];//Example of argument

    callbackId = command.callbackId;
    
    __weak VisionKit* weakSelf = self;

    [self.commandDelegate runInBackground:^{
        @try {
            [weakSelf showScanUI];
        } @catch ( NSException *e ) {
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:e.reason];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self->callbackId];
        }
    }];
}

- (void)showScanUI
{
    // Perform UI operations on the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        self.documentCameraViewController = [VNDocumentCameraViewController new];
        self.documentCameraViewController.delegate = self;
        
        [self.viewController presentViewController:self.documentCameraViewController animated:YES completion:nil];
    });
}

- (void)documentCameraViewController:(VNDocumentCameraViewController *)controller
                   didFinishWithScan:(VNDocumentCameraScan *)scan;
{
    // Present a loading spinner
    UIView* loadingView = [[UIView alloc] init];
    loadingView.frame = CGRectMake(0, 0, 80, 80);
    loadingView.center = self.documentCameraViewController.view.center;
    loadingView.backgroundColor = [UIColor whiteColor];
    loadingView.clipsToBounds = true;
    loadingView.layer.cornerRadius = 10;
    
    UIActivityIndicatorView* spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    
    spinner.center = CGPointMake(loadingView.frame.size.width / 2,
    loadingView.frame.size.height / 2);
    [spinner startAnimating];
    
    // Add the views to the UI
    [loadingView addSubview:spinner];
    [[self.documentCameraViewController view] addSubview:loadingView];
    
    [[self.documentCameraViewController view] setNeedsDisplay];
    
    __weak VisionKit* weakSelf = self;
    
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.5);
    dispatch_after(delay, dispatch_get_main_queue(), ^(void){
        NSMutableArray* images = [@[] mutableCopy];
        CDVPluginResult* pluginResult = nil;

        for (int i = 0; i < [scan pageCount]; i++) {
            NSLog(@"Processing scanned image %d", i);
            
            NSString* filePath = [self tempFilePath:@"jpg"];
            NSLog(@"Got image file path image %d, %@", i, filePath);
            
            UIImage* image = [scan imageOfPageAtIndex: i];
            NSData* imageData = UIImageJPEGRepresentation(image, 0.7);
            
            NSLog(@"Got image data image %d", i);

            NSError* err = nil;

            if (![imageData writeToFile:filePath options:NSAtomicWrite error:&err]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_IO_EXCEPTION messageAsString:[err localizedDescription]];
                [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId: self->callbackId];
                return;
            }
            
            NSLog(@"Adding file to `images` array: %@", filePath);

            [images addObject:filePath];
        }
        
        NSLog(@"%@", images);

        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray: images];
        [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:self->callbackId];
        
        [controller dismissViewControllerAnimated:YES completion:nil];
        NSLog(@"Dismiss scanner");
    });
    
    
}

- (void)documentCameraViewControllerDidCancel:(VNDocumentCameraViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:nil];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray: @[]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void)documentCameraViewController:(VNDocumentCameraViewController *)controller
                    didFailWithError:(NSError *)error {
    [controller dismissViewControllerAnimated:YES completion:nil];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

// Borrowed from https://github.com/apache/cordova-plugin-camera/blob/master/src/ios/CDVCamera.m#L396
- (NSString*)tempFilePath:(NSString*)extension
{
    NSString* docsPath = [NSTemporaryDirectory()stringByStandardizingPath];
    NSFileManager* fileMgr = [[NSFileManager alloc] init]; // recommended by Apple (vs [NSFileManager defaultManager]) to be threadsafe
    NSString* filePath;

    // unique file name
    NSTimeInterval timeStamp;
    NSNumber *timeStampObj;
    
    do {
        timeStamp = [[NSDate date] timeIntervalSince1970];
        timeStampObj = [NSNumber numberWithDouble: timeStamp];
        filePath = [NSString stringWithFormat:@"%@/%@%ld.%@", docsPath, RL_SCAN_PREFIX, [timeStampObj longValue], extension];
    } while ([fileMgr fileExistsAtPath:filePath]);

    return filePath;
}

@end
