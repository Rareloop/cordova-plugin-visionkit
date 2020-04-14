#import "VisionKit.h"

#define RL_SCAN_PREFIX @"rl_scan_"

@implementation VisionKit

- (void)scan:(CDVInvokedUrlCommand*)command {
    // NSString* myarg = [[command arguments] objectAtIndex:0];//Example of argument

    callbackId = command.callbackId;

    @try {
        VNDocumentCameraViewController* documentCameraViewController = [[VNDocumentCameraViewController alloc] init];
        documentCameraViewController.delegate = self;
        [self.viewController presentViewController:documentCameraViewController animated:YES completion:nil];
    } @catch ( NSException *e ) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:e.reason];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    }

}

- (void)documentCameraViewController:(VNDocumentCameraViewController *)controller
                   didFinishWithScan:(VNDocumentCameraScan *)scan;
{
    [controller dismissViewControllerAnimated:YES completion:nil];

    NSMutableArray* images = [@[] mutableCopy];
    CDVPluginResult* pluginResult = nil;

    for (int i = 0; i < [scan pageCount]; i++) {
        UIImage* image = [scan imageOfPageAtIndex: (NSUInteger)i];
        NSString* filePath = [self tempFilePath:@"jpg"];
        NSData* imageData = UIImageJPEGRepresentation(image, 0.7);

        NSError* err = nil;

        if (![imageData writeToFile:filePath options:NSAtomicWrite error:&err]) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_IO_EXCEPTION messageAsString:[err localizedDescription]];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
            return;
        }

        [images addObject:filePath];
    }

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray: images];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void)documentCameraViewControllerDidCancel:(VNDocumentCameraViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:nil];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary: @[]];
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
    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
    NSNumber *timeStampObj = [NSNumber numberWithDouble: timeStamp];
    do {
        filePath = [NSString stringWithFormat:@"%@/%@%ld.%@", docsPath, RL_SCAN_PREFIX, [timeStampObj longValue], extension];
    } while ([fileMgr fileExistsAtPath:filePath]);

    return filePath;
}

@end
