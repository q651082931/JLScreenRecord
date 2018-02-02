//
//  JLRecorderManager.h
//  JLScreenRecordDemo
//
//  Created by 孙金亮 on 2018/2/2.
//  Copyright © 2018年 hiscene. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef void (^VideoCompletionBlock)(NSString * path);

@interface JLRecorderManager : NSObject
@property (nonatomic, readonly) BOOL isRecording;

@property(nonatomic,assign)NSInteger maxRecordTime;//最大录屏时间 defalut 60s
@property(nonatomic,assign)NSInteger minRecordTime;//最大录屏时间 defalut 60s
@property (strong, nonatomic) NSURL *videoURL;//视频文件目标目标地址,不设置也可以
@property(nonatomic,assign)int top_edge; //录屏范围上边距
@property(nonatomic,assign)int buttom_edge;//录屏范围下边距

+ (instancetype)sharedInstance;
- (BOOL)startRecording;
- (void)stopRecordingWithCompletion:(VideoCompletionBlock)completionBlock;
- (void)clear; //单例类必须主动清理
- (void)clearFile;//清理录制缓存文件;

@end
