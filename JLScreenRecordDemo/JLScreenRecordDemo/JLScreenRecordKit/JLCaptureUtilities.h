
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

@interface JLCaptureUtilities : NSObject

// 音频与视频的合并. action的形式如下:
// - (void)mergedidFinish:(NSString *)videoPath WithError:(NSError *)error;
+ (void)mergeVideo:(NSURL *)videoPath andAudio:(NSString *)audioPath andTarget:(id)target andAction:(SEL)action;

@end
