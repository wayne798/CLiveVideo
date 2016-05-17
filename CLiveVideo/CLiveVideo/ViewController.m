//
//  ViewController.m
//  CLiveVideo
//
//  Created by chuanliang on 16/2/25.
//  Copyright © 2016年 chuanliang. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVCaptureDevice.h>
#import "rtmpManager.h"
#import "AudioManager.h"

#define SCREEN_WIDTH ([[UIScreen mainScreen]bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen]bounds].size.height)
#define PHONE_STATUSBAR_HEIGHT 20
#define PHONE_NAVIGATIONBAR_HEIGHT 44
#define PHONE_SCREEN_SIZE (CGSizeMake(SCREEN_WIDTH, SCREEN_HEIGHT - PHONE_STATUSBAR_HEIGHT))
#define IS_IPHONE_5 (fabs((double)[[UIScreen mainScreen] bounds].size.height-(double)568 ) < DBL_EPSILON )

typedef NS_ENUM(NSUInteger, CaptureDevicePosition) {
    /// 后置摄像头
    CaptureDevicePositionBack = 0,
    /// 前置摄像头
    CaptureDevicePositionFront
};

@interface ViewController ()
{
    dispatch_queue_t _queue;
}

@property (nonatomic, strong) AVCaptureSession   *captureSession;
@property (nonatomic, strong) AVCaptureDevice    *captureDevice;
@property (nonatomic, assign) BOOL isRunning;
@property (nonatomic, assign) BOOL  cameraToggling;
@property (nonatomic, assign) CaptureDevicePosition  cameraPosition;
@property (nonatomic, assign) AVCaptureVideoOrientation videoOrientation;

@end

@implementation ViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[rtmpManager getInstance] startRtmpConnect:@"rtmp://121.42.56.177/test/123123"];

    [[AudioManager getInstance] initRecording];
    
    [[x264Manager getInstance] initForX264WithWidth:352 height:288];
    
    [[x264Manager getInstance] initForFilePath];
    
    [self initCameraPosition:CaptureDevicePositionBack videoOrientation:3];
    
    [self setupView];
}

- (void)setupView
{
    localView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.view addSubview:localView];
    UIButton * openVideoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    openVideoButton.frame = CGRectMake(45, self.view.frame.size.height - 44 - 20, 80, 44);
    [openVideoButton setTitle:@"打开视频" forState:UIControlStateNormal];
    [openVideoButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    [openVideoButton addTarget:self action:@selector(startRunning) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:openVideoButton];
    
    UIButton * closeViedoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    closeViedoButton.frame = CGRectMake(self.view.frame.size.width - 45 - 80, self.view.frame.size.height - 44 - 20, 80, 44);
    [closeViedoButton setTitle:@"关闭视频" forState:UIControlStateNormal];
    [closeViedoButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    [closeViedoButton addTarget:self action:@selector(stopRunning) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeViedoButton];
    
    UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(100, 100, 100, 20);
    [button setTitle:@"切换摄像头" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(toggleCamera) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    AVCaptureVideoPreviewLayer * previewLayer = [AVCaptureVideoPreviewLayer layerWithSession: self.captureSession];
    previewLayer.frame = localView.bounds;
    previewLayer.videoGravity= AVLayerVideoGravityResizeAspectFill;
    [localView.layer addSublayer: previewLayer];
}

- (void)initCameraPosition:(CaptureDevicePosition)cameraPosition
          videoOrientation:(AVCaptureVideoOrientation)videoOrientation
{
    self.cameraPosition = cameraPosition;
    self.videoOrientation = videoOrientation;
    self.isRunning = NO;
    self.cameraToggling = NO;
    
    AVCaptureDevicePosition position = AVCaptureDevicePositionBack;
    if (CaptureDevicePositionFront == cameraPosition) {
        position = AVCaptureDevicePositionFront;
    }
    
    // find capture device
    NSArray *devices = [AVCaptureDevice devices];
    for (AVCaptureDevice *device in devices) {
        if ([device hasMediaType:AVMediaTypeVideo]) {
            if (device.position == position) {
                self.captureDevice = device;
                break;
            }
        }
    }
    
    if (nil == self.captureDevice) {
        // No capture device found.
        NSLog(@"CameraSource: There is no camera found in position: %@", (CaptureDevicePositionFront == cameraPosition) ? @"front" : @"back");
        return;
    }
    
    AVCaptureSession * captureSession = [[AVCaptureSession alloc] init];
    AVCaptureDeviceInput * input = nil;
    AVCaptureVideoDataOutput * output = nil;
    input = [[AVCaptureDeviceInput alloc] initWithDevice:self.captureDevice error:nil];
    output = [[AVCaptureVideoDataOutput alloc] init];
    captureSession.sessionPreset = AVCaptureSessionPreset352x288;
    NSDictionary *settings = [[NSDictionary alloc] initWithObjectsAndKeys:
                              [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange], kCVPixelBufferPixelFormatTypeKey,
                              nil];
    output.videoSettings = settings;
    dispatch_queue_t cameraQueue = dispatch_queue_create("com.gn100.camera", 0);
    [output setSampleBufferDelegate:self queue:cameraQueue];
    // add input && output
    if ([captureSession canAddInput:input]) {
        [captureSession addInput:input];
    }
    
    if ([captureSession canAddOutput:output]) {
        [captureSession addOutput:output];
    }
    self.captureSession = captureSession;
//    [self reorientCamera];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)reorientCamera
{
    if (!self.captureSession) {
        return;
    }
    
    AVCaptureSession* session = (AVCaptureSession *)self.captureSession;
    
    for (AVCaptureVideoDataOutput* output in session.outputs) {
        for (AVCaptureConnection * av in output.connections) {
            av.videoOrientation = self.videoOrientation;
            if (self.cameraPosition == CaptureDevicePositionFront) {
                if (av.supportsVideoMirroring) {
                    av.videoMirrored = YES;
                }
            }
        }
    }
}

/**
 *  切换前后摄像头
 */
- (void)toggleCamera
{
    if(!self.captureSession){
        return;
    }
    
    if (self.cameraToggling) {
        return;
    }
    self.cameraToggling = YES;
    
    AVCaptureSession* session = self.captureSession;
    
    CaptureDevicePosition newPosition = CaptureDevicePositionFront;
    if (self.cameraPosition == CaptureDevicePositionFront) {
        newPosition = CaptureDevicePositionBack;
    }
    
    [session beginConfiguration];
    
    AVCaptureInput *currentCameraInput = [session.inputs objectAtIndex:0];
    [session removeInput:currentCameraInput];
    
    AVCaptureDevice *newCamera = nil;
    if (((AVCaptureDeviceInput*)currentCameraInput).device.position == AVCaptureDevicePositionBack) {
        newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
    } else {
        newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
    }
    
    AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:newCamera error:nil];
    [session addInput:newVideoInput];
    
    [session commitConfiguration];
    
    self.captureDevice = newCamera;
    
//    [self refreshFPS];
    
    _cameraPosition = newPosition;
    
    [self reorientCamera];
    
    __weak typeof(self) wself = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(wself) strongSelf = wself;
        strongSelf.cameraToggling = NO;
    });
}

- (void)refreshFPS
{
    NSError *error = nil;
    AVCaptureDevice *captureDevice = self.captureDevice;
    if (![captureDevice lockForConfiguration:&error]) {
        NSLog(@"fail to lockForConfiguration: %@",error.localizedDescription);
    } else {
        NSUInteger frameRate = 15;
        AVFrameRateRange *range = [captureDevice.activeFormat.videoSupportedFrameRateRanges firstObject];
        if (frameRate <= range.maxFrameRate && frameRate >= range.minFrameRate) {
            if ([captureDevice respondsToSelector:@selector(activeVideoMaxFrameDuration)]) {
                captureDevice.activeVideoMaxFrameDuration = CMTimeMake(1, (int32_t)frameRate);
                captureDevice.activeVideoMinFrameDuration = CMTimeMake(1, (int32_t)frameRate);
            }
        }
        
        [captureDevice unlockForConfiguration];
    }
}

- (AVCaptureDevice *)getFrontCamera
{
    //获取前置摄像头设备
    NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in cameras){
        if (device.position == AVCaptureDevicePositionBack)
            return device;
    }
    return [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)pos
{
    AVCaptureDevicePosition position = (AVCaptureDevicePosition)pos;
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    
    return nil;
}

- (void)startRunning
{
    NSLog(@"CameraSource: startRunning");
    [self.captureSession startRunning];
    self.isRunning = YES;
    [[AudioManager getInstance] startRecording];
    
}

- (void)stopRunning
{
    NSLog(@"CameraSource: stopRunning");
    [self.captureSession stopRunning];
    self.isRunning = NO;
    [[AudioManager getInstance] pauseRecording];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
   
    if (CMSampleBufferDataIsReady(sampleBuffer))
    {
        [[x264Manager getInstance] encoderToH264:sampleBuffer];
    }

}

@end
