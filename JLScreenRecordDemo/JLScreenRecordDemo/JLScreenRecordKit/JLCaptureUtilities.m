

#import "JLCaptureUtilities.h"


@implementation JLCaptureUtilities

+ (void)mergeVideo:(NSURL *)videoPath andAudio:(NSString *)audioPath andTarget:(id)target andAction:(SEL)action
{
    NSURL *audioUrl=[NSURL fileURLWithPath:audioPath];
	NSURL *videoUrl= videoPath;
	
	AVURLAsset* audioAsset = [[AVURLAsset alloc]initWithURL:audioUrl options:nil];
	AVURLAsset* videoAsset = [[AVURLAsset alloc]initWithURL:videoUrl options:nil];
	
	//混合音乐
	AVMutableComposition* mixComposition = [AVMutableComposition composition];
	AVMutableCompositionTrack *compositionCommentaryTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio 
																						preferredTrackID:kCMPersistentTrackID_Invalid];
	[compositionCommentaryTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAsset.duration) 
										ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] 
										 atTime:kCMTimeZero error:nil];
	
	
	//混合视频
	AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo 
																				   preferredTrackID:kCMPersistentTrackID_Invalid];
	[compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) 
								   ofTrack:[videoAsset tracksWithMediaType:AVMediaTypeVideo].firstObject
									atTime:kCMTimeZero error:nil];
	AVAssetExportSession* _assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition 
																		  presetName:AVAssetExportPresetPassthrough];   
	
	//[audioAsset release];
    //[videoAsset release];
    
	//保存混合后的文件的过程
	NSString* videoName = @"export.mp4";
	NSString *exportPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:videoName];
	NSURL    *exportUrl = [NSURL fileURLWithPath:exportPath];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:exportPath]) 
	{
		[[NSFileManager defaultManager] removeItemAtPath:exportPath error:nil];
	}
	
	_assetExport.outputFileType = AVFileTypeQuickTimeMovie;
	NSLog(@"file type %@",_assetExport.outputFileType);
	_assetExport.outputURL = exportUrl;
	_assetExport.shouldOptimizeForNetworkUse = YES;
	
	[_assetExport exportAsynchronouslyWithCompletionHandler:
	 ^(void )
    {    
        NSLog(@"完成了%@",_assetExport.error);
		 // your completion code here
      
        [self coverToMp4:exportUrl andTarget:target andAction:action];
 
     }];
    
	//[_assetExport release];


}

+ (void)coverToMp4:(NSURL *)url andTarget:(id)target andAction:(SEL)action{
    
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:url options:nil];
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
    
    if ([compatiblePresets containsObject:AVAssetExportPresetHighestQuality])
        
    {
        
        
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]initWithAsset:avAsset
                                                                              presetName:AVAssetExportPresetHighestQuality];
        NSString* _mp4Path = [NSHomeDirectory() stringByAppendingFormat:@"/Documents/output-JLViode.mp4"];
        if ([[NSFileManager defaultManager]fileExistsAtPath:_mp4Path]) {
            [[NSFileManager defaultManager]removeItemAtPath:_mp4Path error:nil];
        }
        exportSession.outputURL = [NSURL fileURLWithPath: _mp4Path];
        exportSession.shouldOptimizeForNetworkUse = YES;
        exportSession.outputFileType = AVFileTypeMPEG4;
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            switch ([exportSession status]) {
                case AVAssetExportSessionStatusFailed:
                {
                    
                    break;
                }
                    
                case AVAssetExportSessionStatusCancelled:
                    NSLog(@"Export canceled");
                    break;
                case AVAssetExportSessionStatusCompleted:
                    NSLog(@"Successful!");
                    NSLog(@"%@",_mp4Path);
                    
                    if ([target respondsToSelector:action])
                    {
                        [target performSelector:action withObject:_mp4Path withObject:nil];
                    }
                    
                    break;
                default:
                    break;
            }
        }];
    }
    
    
}
//
/////使用AVfoundation添加水印
//+ (void)mergeVideo:(NSURL *)videoPath andAudio:(NSString *)audioPath andTarget:(id)target andAction:(SEL)action
//{
//    if (!videoPath) {
//        return;
//    }
//    //1 创建AVAsset实例 AVAsset包含了video的所有信息 self.videoUrl输入视频的路径
//    //封面图片
//    NSDictionary *opts = [NSDictionary dictionaryWithObject:@(YES) forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
//    AVURLAsset* videoAsset = [AVURLAsset URLAssetWithURL:videoPath options:opts];     //初始化视频媒体文件
//    CMTime startTime = CMTimeMakeWithSeconds(0.2, 600);
//    CMTime endTime = CMTimeMakeWithSeconds(videoAsset.duration.value/videoAsset.duration.timescale-0.2, videoAsset.duration.timescale);
//    //声音采集
//    AVURLAsset * audioAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:audioPath] options:opts];
//    //2 创建AVMutableComposition实例. apple developer 里边的解释 【AVMutableComposition is a mutable subclass of AVComposition you use when you want to create a new composition from existing assets. You can add and remove tracks, and you can add, remove, and scale time ranges.】
//    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
//    //3 视频通道  工程文件中的轨道，有音频轨、视频轨等，里面可以插入各种对应的素材
//    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
//                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
//    //把视频轨道数据加入到可变轨道中 这部分可以做视频裁剪TimeRange
//    [videoTrack insertTimeRange:CMTimeRangeMake(startTime, endTime)
//                        ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
//                         atTime:kCMTimeZero error:nil];
//    //音频通道
//    AVMutableCompositionTrack * audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
//    //音频采集通道
//    AVAssetTrack * audioAssetTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
//    [audioTrack insertTimeRange:CMTimeRangeMake(startTime, endTime) ofTrack:audioAssetTrack atTime:kCMTimeZero error:nil];
//    //3.1 AVMutableVideoCompositionInstruction 视频轨道中的一个视频，可以缩放、旋转等
//    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
//    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, videoTrack.timeRange.duration);
//    // 3.2 AVMutableVideoCompositionLayerInstruction 一个视频轨道，包含了这个轨道上的所有视频素材
//    AVMutableVideoCompositionLayerInstruction *videolayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
//    AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
//    //    UIImageOrientation videoAssetOrientation_  = UIImageOrientationUp;
//    BOOL isVideoAssetPortrait_  = NO;
//    CGAffineTransform videoTransform = videoAssetTrack.preferredTransform;
//    if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
//        //        videoAssetOrientation_ = UIImageOrientationRight;
//        isVideoAssetPortrait_ = YES;
//    }
//    if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
//        //        videoAssetOrientation_ =  UIImageOrientationLeft;
//        isVideoAssetPortrait_ = YES;
//    }
//    //    if (videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0) {
//    //        videoAssetOrientation_ =  UIImageOrientationUp;
//    //    }
//    //    if (videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0) {
//    //        videoAssetOrientation_ = UIImageOrientationDown;
//    //    }
//    [videolayerInstruction setTransform:videoAssetTrack.preferredTransform atTime:kCMTimeZero];
//    [videolayerInstruction setOpacity:0.0 atTime:endTime];
//    // 3.3 - Add instructions
//    mainInstruction.layerInstructions = [NSArray arrayWithObjects:videolayerInstruction,nil];
//    //AVMutableVideoComposition：管理所有视频轨道，可以决定最终视频的尺寸，裁剪需要在这里进行
//    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
//    CGSize naturalSize;
//    if(isVideoAssetPortrait_){
//        naturalSize = CGSizeMake(videoAssetTrack.naturalSize.height, videoAssetTrack.naturalSize.width);
//    } else {
//        naturalSize = videoAssetTrack.naturalSize;
//    }
//    float renderWidth, renderHeight;
//    renderWidth = naturalSize.width;
//    renderHeight = naturalSize.height;
//    mainCompositionInst.renderSize = CGSizeMake(renderWidth, renderHeight);
//    mainCompositionInst.renderSize = CGSizeMake(renderWidth, renderHeight);
//    mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
//    mainCompositionInst.frameDuration = CMTimeMake(1, 25);
//    [self applyVideoEffectsToComposition:mainCompositionInst WithCoverImage:[UIImage ARImageNamed:@"WechatIMG1003"] size:CGSizeMake(renderWidth, renderHeight)];
//    // 4 - 输出路径
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4",@"123123"]];
//    unlink([myPathDocs UTF8String]);
//    NSURL* videoUrl = [NSURL fileURLWithPath:myPathDocs];
//
//    // 5 - 视频文件输出
//   AVAssetExportSession * exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
//                                                presetName:AVAssetExportPresetHighestQuality];
//    exporter.outputURL=videoUrl;
//    exporter.outputFileType = AVFileTypeQuickTimeMovie;
//    exporter.shouldOptimizeForNetworkUse = YES;
//    exporter.videoComposition = mainCompositionInst;
//    [exporter exportAsynchronouslyWithCompletionHandler:^{
//        dispatch_async(dispatch_get_main_queue(), ^{
//            //这里是输出视频之后的操作，做你想做的
//            [self coverToMp4:videoUrl andTarget:target andAction:action];
//        });
//    }];
//}
//
//+ (void)applyVideoEffectsToComposition:(AVMutableVideoComposition *)composition WithCoverImage:(UIImage*)coverImg   size:(CGSize)size {
//
//    //第二个水印
//    CALayer *coverImgLayer = [CALayer layer];
//    coverImgLayer.contents = (id)coverImg.CGImage;
//    //    [coverImgLayer setContentsGravity:@"resizeAspect"];
//    coverImgLayer.frame =  CGRectMake(20,size.height -  40 * [UIScreen mainScreen].scale ,95 * [UIScreen mainScreen].scale, 37.5 *[UIScreen mainScreen].scale );
//
//    // 2 - The usual overlay
//    CALayer *overlayLayer = [CALayer layer];
//    overlayLayer.frame = CGRectMake(0, 0, size.width, size.height);
//    [overlayLayer setMasksToBounds:YES];
//    CALayer *parentLayer = [CALayer layer];
//    CALayer *videoLayer = [CALayer layer];
//    parentLayer.frame = CGRectMake(0, 0, size.width, size.height);
//    videoLayer.frame = CGRectMake(0, 0, size.width, size.height);
//    [parentLayer addSublayer:videoLayer];
//    [parentLayer addSublayer:overlayLayer];
//    [parentLayer addSublayer:coverImgLayer];
//    //设置封面
////    CABasicAnimation *anima = [CABasicAnimation animationWithKeyPath:@"opacity"];
////    anima.fromValue = [NSNumber numberWithFloat:1.0f];
////    anima.toValue = [NSNumber numberWithFloat:0.0f];
////    anima.repeatCount = 0;
////    anima.duration = 5.0f;  //5s之后消失
////    [anima setRemovedOnCompletion:NO];
////    [anima setFillMode:kCAFillModeForwards];
////    anima.beginTime = AVCoreAnimationBeginTimeAtZero;
////    [coverImgLayer addAnimation:anima forKey:@"opacityAniamtion"];
//    composition.animationTool = [AVVideoCompositionCoreAnimationTool
//                                 videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
//}
@end
