#import <Cordova/CDV.h>
#import <VisionKit/VisionKit.h>

@interface VisionKit : CDVPlugin<VNDocumentCameraViewControllerDelegate> {
    NSString* callbackId;
}

- (void) scan:(CDVInvokedUrlCommand*)command;

@end
