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
    
    [self clearFile];
    
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        
        self.screenRecord = [[JLScreenRecorder alloc]init];
        self.audioRecord = [[JLAudioRecord alloc]init];
        [self.audioRecord prepareRecord];
    }
    
    return self;
}
- (void)clearFile{
    [self.screenRecord clearFile];
    [self.audioRecord clearAudioFile];
    
}
- (BOOL)startRecording
{
    
    [self.audioRecord beginRecord];

    return  [self.screenRecord startRecording];
    
    
}

- (void)stopRecordingWithCompletion:(VideoCompletionBlock)completionBlock;
{
    self.completionBlock = completionBlock;
    [self.audioRecord endRecord];
    __weak typeof(self) weakSelf = self;
    [self.screenRecord stopRecordingWithCompletion:^(NSURL *vedioUrl) {
       
            [JLCaptureUtilities mergeVideo:vedioUrl andAudio:weakSelf.audioRecord.recordFilePath andTarget:weakSelf andAction:@selector(mergedidFinish:WithError:)];
        [weakSelf.screenRecord clearFile];
        
    }];
    
}

- (void)mergedidFinish:(NSString *)videoPath WithError:(NSError *)error
{
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
@end
