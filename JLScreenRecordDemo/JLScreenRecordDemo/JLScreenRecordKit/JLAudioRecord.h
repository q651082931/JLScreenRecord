
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AudioToolbox/AudioToolbox.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>

@protocol JLAudioRecordDelegate<NSObject>
-(void)wavComplete;
@end


@interface JLAudioRecord : NSObject

@property (retain, nonatomic)   AVAudioRecorder     *recorder;
@property (copy, nonatomic)     NSString            *recordFileName;//录音文件名
@property (copy, nonatomic)     NSString            *recordFilePath;//录音文件路径
@property (assign,nonatomic) BOOL nowPause;
@property (nonatomic, assign) id<JLAudioRecordDelegate>delegate;
- (void)beginRecordByFileName:(NSString*)_fileName;
- (void)endRecord;
@end
