//
//  JLRecorderManager.m
//  JLScreenRecordDemo
//
//  Created by 孙金亮 on 2018/2/2.
//  Copyright © 2018年 hiscene. All rights reserved.
//

#import "JLRecorderManager.h"
#import "JLAudioRecord.h"
#import "JLScreenRecorder.h"
#import "JLCaptureUtilities.h"


@interface JLRecorderManager()

@property(nonatomic,strong) JLAudioRecord * audioRecord;
@property(nonatomic,copy) VideoCompletionBlock completionBlock;
@property(nonatomic,strong)JLScreenRecorder * screenRecord;
@property(nonatomic,strong)NSTimer * timer_record_time;
@property(nonatomic,assign)NSTimeInterval timer_count ;

@end

@implementation JLRecorderManager



#pragma mark - initializers
static dispatch_once_t once;
static JLRecorderManager * sharedInstance;


+ (instancetype)sharedInstance {
    
    
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}
- (void)clear{
    once = 0;
    sharedInstance = nil;
    
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [self clearFile];
    
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        
        self.screenRecord = [[JLScreenRecorder alloc]init];
        self.audioRecord = [[JLAudioRecord alloc]init];
        [self.audioRecord prepareRecord];
        self.minRecordTime = 3;
        self.maxRecordTime = 60;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionWasInterrupted:) name:AVAudioSessionInterruptionNotification object:nil];
    }
    
    return self;
}
- (void)clearFile{
    [self.screenRecord clearFile];
    [self.audioRecord clearAudioFile];
    
}
- (BOOL)startRecording
{
    
    if (self.isRecording) {
        return NO ;
    }
    [self starTimer];
    [self.audioRecord beginRecord];
    _isRecording =  [self.screenRecord startRecording];
    
    if ([self.delegate respondsToSelector:@selector(JLRecorderManagerStartRecord:)]) {
        
        [self.delegate JLRecorderManagerStartRecord:self];
    }
    
    return  self.isRecording ;
    
    
}

- (void)stopRecordingWithCompletion:(VideoCompletionBlock)completionBlock;
{
    if (self.isRecording == NO) {
        return;
    }
    if (completionBlock) {
        self.completionBlock = completionBlock;
    }
    self.completionBlock = completionBlock;
    [self stopTimer];
    [self.audioRecord endRecord];
    __weak typeof(self) weakSelf = self;
    [self.screenRecord stopRecordingWithCompletion:^(NSURL *vedioUrl) {
       
        [JLCaptureUtilities mergeVideo:vedioUrl andAudio:weakSelf.audioRecord.recordFilePath andTarget:weakSelf andAction:@selector(mergedidFinish:WithError:)];
        [weakSelf clearFile];
        
    }];
    
}

- (void)mergedidFinish:(NSString *)videoPath WithError:(NSError *)error
{
    _isRecording = NO;
    if ([self.delegate respondsToSelector:@selector(JLRecorderManagerStopRecord:recordTime:)]) {
        
        [self.delegate JLRecorderManagerStopRecord:self recordTime:self.timer_count];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.completionBlock) self.completionBlock(videoPath);
    });
}

- (void)setTop_edge:(int)top_edge{
    _top_edge = top_edge;
    self.screenRecord.top_edge = top_edge;
    
    
}
-(void)setButtom_edge:(int)buttom_edge{
    _buttom_edge = buttom_edge;
    self.screenRecord.buttom_edge = buttom_edge;
    
    
}

- (void)audioSessionWasInterrupted:(NSNotification *)notification{
    
    NSLog(@"the notification is %@",notification);
    if (AVAudioSessionInterruptionTypeBegan == [notification.userInfo[AVAudioSessionInterruptionTypeKey] intValue])
    {
        
        [self stopRecordingWithCompletion:nil];
        NSLog(@"begin");
    }
    else if (AVAudioSessionInterruptionTypeEnded == [notification.userInfo[AVAudioSessionInterruptionTypeKey] intValue])
    {
        NSLog(@"begin - end");
    }
    
    
}

#pragma mark/******************* Timer *******************/


- (void)starTimer{
    
    [self stopTimer];
    self.timer_count = 0;
    self.timer_record_time = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(updateTimer) userInfo:nil repeats:YES];
    
    [[NSRunLoop mainRunLoop]addTimer:self.timer_record_time forMode:NSRunLoopCommonModes];
    
}


- (void)stopTimer{
    
    [self.timer_record_time invalidate];
    self.timer_record_time = nil;
    
}

- (void)updateTimer{
    
    self.timer_count+=0.1;
    
    if ([self.delegate respondsToSelector:@selector(JLRecorderManagerRecording:recordTime:)]) {
        
        [self.delegate JLRecorderManagerRecording:self recordTime:self.timer_count];
    }

    
    if (self.timer_count > self.maxRecordTime) {
        
        [self stopRecordingWithCompletion:nil];
    }
    
}
@end
