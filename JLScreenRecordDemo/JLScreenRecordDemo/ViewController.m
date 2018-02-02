//
//  ViewController.m
//  JLScreenRecordDemo
//
//  Created by 孙金亮 on 2018/2/2.
//  Copyright © 2018年 hiscene. All rights reserved.
//

#import "ViewController.h"
#import "JLScreenRecorder.h"
#import "OpenGLView.h"
#import "HiARCapture.h"
#import <MediaPlayer/MediaPlayer.h>
#import "UIView+UIView___Extension.h"
#import "glViewController.h"

@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>

@property(nonatomic,weak)OpenGLView * openGLView;

@property (nonatomic, strong) HiARCapture *capture;
@property(nonatomic,strong)dispatch_queue_t captureQueue;
@property (nonatomic, strong) AVCaptureVideoDataOutput *captureVideoDataOutput;
@property(nonatomic,weak)UIButton * button_record;
@property(nonatomic,strong)MPMoviePlayerController * playVC;
@property(nonatomic,strong)UIButton * button_return;
@property(nonatomic,strong)glViewController * glVC;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    [self initCamera];
    [self initView];
    
}
- (void)initView{
    
    [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    

    
    
    self.button_return = [[UIButton alloc] init];
    
    [self.button_return setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
    self.button_return.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.button_return sizeToFit];
    [self.button_return addTarget:self action:@selector(backButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    self.button_return.hidden = YES;
    [self.view addSubview:self.button_return];
    self.glVC = [[glViewController alloc]init];
    self.glVC.view.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.glVC.view];
    
    
    UIButton * button_record = [[UIButton alloc]init];
    self.button_record = button_record;
    
    [self.view addSubview:button_record];
    
    [button_record setBackgroundImage:[UIImage imageNamed:@"photo"] forState:UIControlStateNormal];
    [button_record setBackgroundImage:[UIImage imageNamed:@"photo_active"] forState:UIControlStateHighlighted];
    [button_record sizeToFit];
    [button_record setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    UILongPressGestureRecognizer * longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(recordButtonLongPress:)];
    [self.button_record addGestureRecognizer:longPress];
    
    
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    self.button_record.centerX = self.view.width * 0.5;
    self.button_record.y = self.view.height - 40 - self.button_record.height;
    self.button_return.origin = CGPointMake(30, 30);
    self.glVC.view.frame = self.view.bounds;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    [self.capture start];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    
    
    
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    
    [self.capture stop];
    
}
- (void)dealloc{
    
    [self deinitCamera];
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    
    return UIStatusBarStyleLightContent;
}

- (void)backButtonClicked{
    
    self.button_return.hidden = YES;
    [self.playVC.view removeFromSuperview];
    self.playVC = nil;
    
}

#pragma mark - /************************** ScreenRecord   **************************/

- (void)recordButtonLongPress:(UILongPressGestureRecognizer *)ges{
    
    
    if (ges.state ==  UIGestureRecognizerStateBegan) {
        
        
        
        dispatch_async(dispatch_get_main_queue(), ^{

            [[JLScreenRecorder sharedInstance]startRecording];
            
        });
        
        
        
        
    }else if (ges.state == UIGestureRecognizerStateEnded){
        
            [[JLScreenRecorder sharedInstance]stopRecordingWithCompletion:^(NSString *path) {
                
                MPMoviePlayerController * playerVC = [[MPMoviePlayerController alloc]initWithContentURL:[NSURL fileURLWithPath:path]];
                
                playerVC.shouldAutoplay = YES;
                [playerVC prepareToPlay];
                self.playVC = playerVC;
                [self.view addSubview:self.playVC.view];
                self.playVC.view.frame = self.view.bounds;
                self.button_return.hidden = NO;
                [self.view bringSubviewToFront:self.button_return];
                
            }];
        
    }else if (ges.state == UIGestureRecognizerStateCancelled || ges.state == UIGestureRecognizerStateFailed){
        
        
        [self recordScreenfail];
        
    }
    
    
}
- (void)recordScreenfail{
    
    
    [[JLScreenRecorder sharedInstance]stopRecordingWithCompletion:^(NSString *path) {
        
    }];
}




#pragma mark - /************************** Camera Settings **************************/

- (void)initCamera {
    if (!self.capture) {
        
        OpenGLView *openGLView = [[OpenGLView alloc] initWithFrame:self.view.bounds];
        [self.view addSubview:openGLView];
        _openGLView = openGLView;
        openGLView.backgroundColor = [UIColor blackColor];
        
        _captureQueue = dispatch_queue_create("com.captureSesstionQueue", DISPATCH_QUEUE_SERIAL);
        self.capture = [[HiARCapture alloc] initWithSessionPreset:AVCaptureSessionPreset640x480
                                                   devicePosition:AVCaptureDevicePositionBack
                                                     sessionQueue:_captureQueue];
        
        dispatch_async( _captureQueue, ^{
            [self configCaptureVideoDataOutput];
        });
    }
}

- (void)configCaptureVideoDataOutput {
    if ( self.capture.setupResult != AVCaptureSetupResultSuccess ) {
        return;
    }
    
    [self.capture.session beginConfiguration];
    /*
     Use the status bar orientation as the initial video orientation. Subsequent orientation changes are
     handled by -[AVCamCameraViewController viewWillTransitionToSize:withTransitionCoordinator:].
     */
    UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
    AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
    if ( statusBarOrientation != UIInterfaceOrientationUnknown ) {
        initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
    }
//    self.capturePreview.videoPreviewLayer.connection.videoOrientation = initialVideoOrientation;
    
    self.captureVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.captureVideoDataOutput setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey:
                                                        [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]}];
    __weak typeof(self) weakSelf = self;
    [self.captureVideoDataOutput setSampleBufferDelegate:weakSelf queue:_captureQueue];
    
    if ([self.capture.session canAddOutput:self.captureVideoDataOutput]) {
        [self.capture.session addOutput:self.captureVideoDataOutput];
    } else {
#if DEBUG
        NSLog( @"Could not add video device output to the session" );
#endif
        self.capture.setupResult = AVCaptureSetupResultSessionConfigurationFailed;
        [self.capture.session commitConfiguration];
        return;
    }
    
    AVCaptureConnection *videoConnection = [self.captureVideoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([videoConnection isVideoOrientationSupported]) {
        videoConnection.videoOrientation = AVCaptureVideoOrientationLandscapeRight; // HiAR SDK only support landscape
    }
    
    [self.capture.session commitConfiguration];
}

- (void)checkCaptureSetupResult {
    dispatch_async( _captureQueue, ^{
        switch ( self.capture.setupResult ) {
            case AVCaptureSetupResultSuccess: {
                // Only setup observers and start the session running if setup succeeded.
                dispatch_async( dispatch_get_main_queue(), ^{
                    [self.capture start];
                });
                break;
            }
            case AVCaptureSetupResultCameraNotAuthorized: {
                dispatch_async( dispatch_get_main_queue(), ^{
                    NSString *message = @"无获取镜头信息权限,请您设置";
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:cancelAction];
                    // Provide quick access to Settings.
                    UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:@"设置" style:UIAlertActionStyleDefault handler:^( UIAlertAction *action ) {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
                    }];
                    [alertController addAction:settingsAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                });
                break;
            }
            case AVCaptureSetupResultSessionConfigurationFailed: {
                dispatch_async( dispatch_get_main_queue(), ^{
                    NSString *message = @"连接镜头有误";
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:cancelAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                });
                break;
            }
        }
    });
}

- (void)deinitCamera {
    [self.capture close];
}


#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate


- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    
    [self.openGLView processWithSampleBuffer:sampleBuffer];

}

@end
