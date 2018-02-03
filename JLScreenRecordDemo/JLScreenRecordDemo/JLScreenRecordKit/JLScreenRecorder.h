
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^VideoCompletionBlock)(NSString * path);

@protocol JLScreenRecorderDelegate;

@interface JLScreenRecorder : NSObject

@property (nonatomic, readonly) BOOL isRecording;
@property (nonatomic, weak) id <JLScreenRecorderDelegate> delegate;

@property (strong, nonatomic) NSURL *videoURL;//视频文件目标目标地址,不设置也可以
@property(nonatomic,assign)CGFloat top_edge; //录屏范围上边距
@property(nonatomic,assign)CGFloat buttom_edge;//录屏范围下边距



- (BOOL)startRecording;
- (void)stopRecordingWithCompletion:(void (^)(NSURL * vedioUrl))completionBlock;
+ (void)clear; //单例类必须主动清理
- (void)clearFile;//清理录制缓存文件;

@end

