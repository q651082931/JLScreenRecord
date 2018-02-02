
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^VideoCompletionBlock)(NSString * path);

@protocol JLScreenRecorderDelegate;

@interface JLScreenRecorder : NSObject

@property (nonatomic, readonly) BOOL isRecording;
@property (nonatomic, weak) id <JLScreenRecorderDelegate> delegate;

@property(nonatomic,assign)NSInteger maxRecordTime;//最大录屏时间 defalut 60s
@property (strong, nonatomic) NSURL *videoURL;//视频文件目标目标地址,不设置也可以
@property(nonatomic,assign)CGFloat top_edge;
@property(nonatomic,assign)CGFloat buttom_edge;


+ (instancetype)sharedInstance;
- (BOOL)startRecording;
- (void)stopRecordingWithCompletion:(VideoCompletionBlock)completionBlock;
+ (void)clear; //单例类必须主动清理
- (void)clearFile;//清理录制缓存文件;

@end

