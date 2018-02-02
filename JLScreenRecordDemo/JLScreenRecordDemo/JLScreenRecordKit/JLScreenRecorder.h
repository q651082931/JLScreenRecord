
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
typedef void (^VideoCompletionBlock)(NSString * path);
@protocol JLScreenRecorderDelegate;

@interface JLScreenRecorder : NSObject
@property (nonatomic, readonly) BOOL isRecording;

// delegate is only required when implementing JLScreenRecorderDelegate - see below
@property (nonatomic, weak) id <JLScreenRecorderDelegate> delegate;

// if saveURL is nil, video will be saved into camera roll
// this property can not be changed whilst recording is in progress
@property (strong, nonatomic) NSURL *videoURL;
@property(nonatomic,assign)CGFloat top_edge;
@property(nonatomic,assign)CGFloat buttom_edge;
+ (instancetype)sharedInstance;
- (BOOL)startRecording;
- (void)stopRecordingWithCompletion:(VideoCompletionBlock)completionBlock;
@end


// If your view contains an AVCaptureVideoPreviewLayer or an openGL view
// you'll need to write that data into the CGContextRef yourself.
// In the viewcontroller responsible for the AVCaptureVideoPreviewLayer / openGL view
// set yourself as the delegate for JLScreenRecorder.
// [JLScreenRecorder sharedInstance].delegate = self
// Then implement 'writeBackgroundFrameInContext:(CGContextRef*)contextRef'
// use 'CGContextDrawImage' to draw your view into the provided CGContextRef
@protocol JLScreenRecorderDelegate <NSObject>
- (void)writeBackgroundFrameInContext:(CGContextRef*)contextRef;
@end
