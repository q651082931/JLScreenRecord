

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
@interface OpenGLView : UIView

- (void)processWithSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end
