#import <Cordova/CDV.h>
#import <VisionKit/VisionKit.h>

@interface VisionKit : CDVPlugin<VNDocumentCameraViewControllerDelegate> {
    NSString* callbackId;
}

@property (strong) VNDocumentCameraViewController* documentCameraViewController;

- (void) scan:(CDVInvokedUrlCommand*)command;

@end
