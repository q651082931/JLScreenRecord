
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AudioToolbox/AudioToolbox.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>

@protocol JLAudioRecordDelegate<NSObject>
-(void)wavComplete;
@end


@interface JLAudioRecord : NSObject


@property (copy, nonatomic)     NSString  *recordFilePath;//录音文件路径
@property (assign,nonatomic) BOOL nowPause;
@property (nonatomic, assign) id<JLAudioRecordDelegate>delegate;
- (void)beginRecord;
- (void)endRecord;
- (void)clearAudioFile;
@end
