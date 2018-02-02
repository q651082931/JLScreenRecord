

#import "HiARCapture.h"
#import <AVFoundation/AVFoundation.h>

@interface HiARCapture ()

@property (nonatomic) dispatch_queue_t sessionQueue;

@end

@implementation HiARCapture {
    AVCaptureDeviceInput *_deviceInput;
    BOOL _isRunning;
}



// The method is deserted
- (instancetype)init {
    _sessionQueue = dispatch_queue_create("com.captureSesstionQueue", DISPATCH_QUEUE_SERIAL);
    return [self initWithSessionPreset:AVCaptureSessionPresetHigh
                        devicePosition:AVCaptureDevicePositionBack
                          sessionQueue:_sessionQueue];
}

- (instancetype)initWithSessionPreset:(NSString *)sessionPreset
                       devicePosition:(AVCaptureDevicePosition)position
                         sessionQueue:(dispatch_queue_t)queue {
    self = [super init];
    if (self) {
        // Create the AVCaptureSession.
        _session = [[AVCaptureSession alloc] init];
        
        // Communicate with the session and other session objects on this queue.
        _sessionQueue = queue;
        
        _setupResult = AVCaptureSetupResultSuccess;
        
        _position = position; // AVCaptureDevicePositionBack
        _sessionPreset = sessionPreset; // AVCaptureSessionPresetHigh
        
        _isRunning = NO;
    
        /*
         Check video authorization status. Video access is required and audio
         access is optional. If audio access is denied, audio is not recorded
         during movie recording.
         */
        switch ( [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] ) {
            case AVAuthorizationStatusAuthorized: {
                // The user has previously granted access to the camera.
                break;
            }
            case AVAuthorizationStatusNotDetermined: {
                /*
                 The user has not yet been presented with the option to grant
                 video access. We suspend the session queue to delay session
                 setup until the access request has completed.
                 
                 Note that audio access will be implicitly requested when we
                 create an AVCaptureDeviceInput for audio during session setup.
                 */
                dispatch_suspend( _sessionQueue );
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^( BOOL granted ) {
                    if ( ! granted ) {
                        _setupResult = AVCaptureSetupResultCameraNotAuthorized;
                    }
                    dispatch_resume( _sessionQueue );
                }];
                break;
            }
            default: {
                // The user has previously denied access.
                _setupResult = AVCaptureSetupResultCameraNotAuthorized;
                break;
            }
        }
        
        /*
         Setup the capture session.
         In general it is not safe to mutate an AVCaptureSession or any of its
         inputs, outputs, or connections from multiple threads at the same time.
         
         Why not do all of this on the main queue?
         Because -[AVCaptureSession startRunning] is a blocking call which can
         take a long time. We dispatch session setup to the sessionQueue so
         that the main queue isn't blocked, which keeps the UI responsive.
         */
        dispatch_async( _sessionQueue, ^{
            [self configureSession];
        } );
    }
    return self;
}

- (void)dealloc {
    if ( _isRunning ) {
        [self stop];
    }
}

- (void)start {
    dispatch_async( self.sessionQueue, ^{
        if ( _setupResult == AVCaptureSetupResultSuccess ) {
            [_session startRunning];
            _isRunning = YES;
        }
    });
}

- (void)close {
    dispatch_async( self.sessionQueue, ^{
        if ( _setupResult == AVCaptureSetupResultSuccess ) {
            [_session stopRunning];
            [_session removeInput:_deviceInput];
            _session = nil;
            _deviceInput = nil;
            _isRunning = NO;
        }
    });
}

- (void)stop {
    dispatch_async( self.sessionQueue, ^{
        if ( _setupResult == AVCaptureSetupResultSuccess ) {
            [_session stopRunning];
            _isRunning = NO;
        }
    });
}

- (void)setFlashMode:(AVCaptureFlashMode)flashMode {
    dispatch_async( self.sessionQueue, ^{
        if (_flashMode != flashMode) {
            _flashMode = flashMode;
            if ( _setupResult != AVCaptureSetupResultSuccess) return;
            [self setFlashMode:flashMode forDevice:_deviceInput.device];
        }
    });
}

- (void)setTorchMode:(AVCaptureTorchMode)torchMode {
    dispatch_async( self.sessionQueue, ^{
        if (_torchMode != torchMode) {
            _torchMode = torchMode;
            if ( _setupResult != AVCaptureSetupResultSuccess) return;
            [self setTorchMode:torchMode forDevice:_deviceInput.device];
        }
    });
}

- (void)setFocusMode:(AVCaptureFocusMode)focusMode {
    dispatch_async( self.sessionQueue, ^{
        if (_focusMode != focusMode) {
            _focusMode = focusMode;
            if ( _setupResult != AVCaptureSetupResultSuccess) return;
            [self setFocusMode:focusMode forDevice:_deviceInput.device];
        }
    });
}

- (void)setActiveVideoFrame:(NSInteger)activeVideoFrame {
    dispatch_async( self.sessionQueue, ^{
        if (_activeVideoFrame != activeVideoFrame) {
            _activeVideoFrame = activeVideoFrame;
            if ( _setupResult != AVCaptureSetupResultSuccess) return;
            [self setActiveVideoFrame:_activeVideoFrame forDevice:_deviceInput.device];
        }
    });
}

- (void)configureSession {
    if ( _setupResult != AVCaptureSetupResultSuccess ) {
        return;
    }
    
    NSError *error = nil;
    
    [_session beginConfiguration];
    
    /*
     We do not create an AVCaptureMovieFileOutput when setting up the session because the
     AVCaptureMovieFileOutput does not support movie recording with AVCaptureSessionPresetPhoto.
     */
    _session.sessionPreset = _sessionPreset;
    
    // Add video input.
    AVCaptureDevice *device = [self cameraWithPosition:_position];
    // Choose the back dual camera if available, otherwise default to a wide angle camera.

    
    
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if ( ! deviceInput ) {
#if DEBUG
        NSLog( @"Could not create video device input: %@", error );
#endif
        _setupResult = AVCaptureSetupResultSessionConfigurationFailed;
        [_session commitConfiguration];
        return;
    }
    if ( [_session canAddInput:deviceInput] ) {
        [_session addInput:deviceInput];
        _deviceInput = deviceInput;
    } else {
#if DEBUG
        NSLog( @"Could not add video device input to the session" );
#endif
        _setupResult = AVCaptureSetupResultSessionConfigurationFailed;
        [_session commitConfiguration];
        return;
    }
    
    [_session commitConfiguration];
    
    self.device = device;
}

- (void)ChangePosition{
    
    NSArray *inputs = self.session.inputs;
    for ( AVCaptureDeviceInput *input in inputs ) {
        AVCaptureDevice *device = input.device;
        if ( [device hasMediaType:AVMediaTypeVideo] ) {
            AVCaptureDevicePosition position = device.position;
            AVCaptureDevice *newCamera = nil;
            AVCaptureDeviceInput *newInput = nil;
            
            if (position == AVCaptureDevicePositionFront){
                
                newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
                
            }else{
                newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
            }
            
            newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
            
            // beginConfiguration ensures that pending changes are not applied immediately
            [self.session beginConfiguration];
            
            [self.session removeInput:input];
            [self.session addInput:newInput];
            
            // Changes take effect once the outermost commitConfiguration is invoked.
            [self.session commitConfiguration];
            _position = newCamera.position;
        }
    }
}
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice *device in devices )
        if ( device.position == position )
            return device;
    return nil;
}

#pragma mark - Utils

- (void)setFlashMode:(AVCaptureFlashMode)flashMode forDevice:(AVCaptureDevice *)device {
    if ( device.hasFlash && [device isFlashModeSupported:flashMode] ) {
        NSError *error = nil;
        if ( [device lockForConfiguration:&error] ) {
            device.flashMode = flashMode;
            [device unlockForConfiguration];
        } else {
#if DEBUG
            NSLog( @"Could not lock device for configuration: %@", error );
#endif
        }
    }
}

- (void)setTorchMode:(AVCaptureTorchMode)torchMode forDevice:(AVCaptureDevice *)device {
    if ( device.hasTorch && [device isTorchModeSupported:torchMode] ) {
        NSError *error = nil;
        if ( [device lockForConfiguration:&error] ) {
            device.torchMode = torchMode;
            [device unlockForConfiguration];
        } else {
#if DEBUG
            NSLog( @"Could not lock device for configuration: %@", error );
#endif
        }
    }
}

- (void)setFocusMode:(AVCaptureFocusMode)focusMode forDevice:(AVCaptureDevice *)device {
    if ( [device isFocusModeSupported:focusMode] ) {
        NSError *error = nil;
        if ( [device lockForConfiguration:&error] ) {
            device.focusMode = focusMode;
            [device unlockForConfiguration];
        } else {
#if DEBUG
            NSLog( @"Could not lock device for configuration: %@", error );
#endif
        }
    }
}

- (void)setActiveVideoFrame:(NSInteger)activeVideoFrame forDevice:(AVCaptureDevice *)device {
    NSError *error;
    CMTime frameDuration = CMTimeMake(1, (int32_t)activeVideoFrame);
    NSArray *supportedFrameRateRanges = [device.activeFormat videoSupportedFrameRateRanges];
    BOOL frameRateSupported = NO;
    for (AVFrameRateRange *range in supportedFrameRateRanges) {
        if (CMTIME_COMPARE_INLINE(frameDuration, >=, range.minFrameDuration) &&
            CMTIME_COMPARE_INLINE(frameDuration, <=, range.maxFrameDuration)) {
            frameRateSupported = YES;
        }
    }
    
    if (frameRateSupported && [device lockForConfiguration:&error]) {
        [device setActiveVideoMaxFrameDuration:frameDuration];
        [device setActiveVideoMinFrameDuration:frameDuration];
        [device unlockForConfiguration];
    } else {
#if DEBUG
        NSLog( @"Could not lock device for configuration or not supported frame rate: %@", error );
#endif
    }
}

@end
