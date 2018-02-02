

#import "JLAudioRecord.h"


static NSString * const  JLAudio =  @"JLAudio";
@interface JLAudioRecord()

@property (retain, nonatomic)   AVAudioRecorder     * audioRecorder;
@end

@implementation JLAudioRecord


#pragma mark - 开始录音
- (void)beginRecord{
    
    [self clearAudioFile];
    //初始化录音
    AVAudioRecorder * audioRecorder = [[AVAudioRecorder alloc]initWithURL:[NSURL URLWithString:[self.recordFilePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
                                                       settings:[self getAudioRecorderSettingDict]
                                                          error:nil];
    self.audioRecorder = audioRecorder;
    
    [self.audioRecorder prepareToRecord];

    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord error:nil];
    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    [self.audioRecorder record];
}

- (NSString *)recordFilePath{
    
    if (_recordFilePath.length == 0) {
        //设置文件名和录音路径
        _recordFilePath = [self getPathByFileName:JLAudio ofType:@"wav"];
    }
    return _recordFilePath;
    
}
- (void)clearAudioFile{
    
    
    if ([[NSFileManager defaultManager]fileExistsAtPath:self.recordFilePath]) {
        
        [[NSFileManager defaultManager]removeItemAtPath:self.recordFilePath error:nil];
    }
}

#pragma mark - 开始或结束
-(void)toRecordOrPause:(NSNotification*)sender
{
    NSString* str=(NSString*)[sender object];
    if ([str intValue]) {
        [self startRecord];
    }
    else{
        [self pauseRecord];
    }
}

#pragma mark - 录音开始
-(void)startRecord{
    [self.audioRecorder record];
    _nowPause=NO;
}

#pragma mark - 录音暂停
-(void)pauseRecord{
    if (self.audioRecorder.isRecording) {
        [self.audioRecorder pause];
        _nowPause=YES;
    }
}

#pragma mark - 录音结束
- (void)endRecord{
    if (self.audioRecorder.isRecording||(!self.audioRecorder.isRecording&&_nowPause)) {
        [self.audioRecorder stop];
        self.audioRecorder = nil;
        
        if ([self.delegate respondsToSelector:@selector(wavComplete)]) {
            [self.delegate wavComplete];
        }
        
    }
    
}

- (NSString*)getPathByFileName:(NSString *)_fileName ofType:(NSString *)_type
{
    NSString* fileDirectory = [[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0]stringByAppendingPathComponent:_fileName]stringByAppendingPathExtension:_type];
    return fileDirectory;
}

- (NSDictionary*)getAudioRecorderSettingDict
{
    NSDictionary *recordSetting = [[NSDictionary alloc] initWithObjectsAndKeys:
                                   [NSNumber numberWithFloat: 8000.0],AVSampleRateKey, //采样率
                                   [NSNumber numberWithInt: kAudioFormatLinearPCM],AVFormatIDKey,
                                   [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,//采样位数 默认 16
                                   [NSNumber numberWithInt: 1], AVNumberOfChannelsKey,//通道的数目
                                   nil];
    return recordSetting;
}


@end
