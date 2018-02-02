
#import <UIKit/UIKit.h>

@class AVCaptureVideoPreviewLayer;
@class AVCaptureSession;

@interface HiARCapturePreview : UIView

@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic) AVCaptureSession *session;

@end
