//
//  ViewController.m
//  CymFaceDemo
//
//  Created by 常永梅 on 2021/7/7.
//

#import "ViewController.h"
#import "GLKitView.h"
#import "Utility.h"
#import "ASFVideoProcessor.h"
#import <ArcSoftFaceEngine/ArcSoftFaceEngine.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

#define imgeWidth (self.glView.frame.size.width*2)
#define imgeHight (self.glView.frame.size.height*2)
#define SCREEN_HEIGHT       CGRectGetHeight([UIScreen mainScreen].bounds)/*获取屏幕高度*/
#define SCREEN_WIDTH        CGRectGetWidth([UIScreen mainScreen].bounds)/*获取屏幕宽度*/
#define AKT_FaceCircleW 300 // 设置人脸识别 圆框的直径  (SCREEN_WIDTH-150)
#define AKT_Face3DAngle 10  // 设置人脸的偏航角度

@interface ViewController ()<ASFVideoProcessorDelegate,AVCaptureVideoDataOutputSampleBufferDelegate>
{
    BOOL isback; // 0后摄像头 1前摄像头 默认后摄像头
    // 人脸识别
    ASF_CAMERA_DATA*   _offscreenIn;
    AVCaptureConnection *videoConnection;
    UIView *faceRectView;
    CGFloat angle;
}
@property (nonatomic,strong) AVCaptureSession * captureSession;
@property (nonatomic, strong) ASFVideoProcessor* videoProcessor;
@property (nonatomic, strong) NSMutableArray* arrayAllFaceRectView;
@property (weak, nonatomic) IBOutlet GLKitView *glView;
@property (weak, nonatomic) IBOutlet UIButton *btnChangefaceFrond;
@property (weak, nonatomic) IBOutlet UILabel *labFace;
@property (weak, nonatomic) IBOutlet UIImageView *imgFaceC;
//@property (weak, nonatomic) IBOutlet NSLayoutConstraint *faceCircleH;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
 
    angle = 0; // 旋转角度
    isback = false;
//    self.faceCircleH.constant = SCREEN_WIDTH-100;
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setFaceCamera];
    [self startAnimation]; // 开始动画旋转
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self startCaptureSession];
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
}
#pragma mark -
- (IBAction)btnChangeCamera:(UIButton *)sender {
    isback =! isback;
    [self stopCaptureSession];
    
    [self setupCaptureSession:(AVCaptureVideoOrientation)[[UIApplication sharedApplication] statusBarOrientation] isFront:isback];
    [self startCaptureSession];
}

#pragma mark - face camera info
-(void)setFaceCamera{
    UIInterfaceOrientation uiOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    AVCaptureVideoOrientation videoOrientation = (AVCaptureVideoOrientation)uiOrientation;
    
    self.arrayAllFaceRectView = [NSMutableArray arrayWithCapacity:0];
    
    self.videoProcessor = [[ASFVideoProcessor alloc] init];
    self.videoProcessor.delegate = self;
    [self.videoProcessor initProcessor];
    
    [self setupCaptureSession:videoOrientation isFront:isback]; // 摄像权限
}
- (AVCaptureDevice *)videoDeviceWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
        if ([device position] == position)
            return device;
    
    return nil;
}
- (BOOL) setupCaptureSession:(AVCaptureVideoOrientation)videoOrientation isFront:(BOOL)isFront
{
    self.captureSession = [[AVCaptureSession alloc] init];
    
    [self.captureSession beginConfiguration];
    
    AVCaptureDevice *videoDevice = [self videoDeviceWithPosition:isFront ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack];// 前、后摄像头
    // 创建输入流
    AVCaptureDeviceInput *videoIn = [[AVCaptureDeviceInput alloc] initWithDevice:videoDevice error:nil];
    if ([self.captureSession canAddInput:videoIn])
        [self.captureSession addInput:videoIn];
    // 创建输出流
    AVCaptureVideoDataOutput *videoOut = [[AVCaptureVideoDataOutput alloc] init];
    [videoOut setAlwaysDiscardsLateVideoFrames:YES];
    
#ifdef __OUTPUT_BGRA__
    NSDictionary *dic = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
#else
    NSDictionary *dic = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
#endif
    [videoOut setVideoSettings:dic];
    
    dispatch_queue_t videoCaptureQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0);
    [videoOut setSampleBufferDelegate:self queue:videoCaptureQueue];
    
    if ([self.captureSession canAddOutput:videoOut])
        [self.captureSession addOutput:videoOut];
    videoConnection = [videoOut connectionWithMediaType:AVMediaTypeVideo];
    
    if (videoConnection.supportsVideoMirroring) {
        [videoConnection setVideoMirrored:TRUE];
    }
    
    if ([videoConnection isVideoOrientationSupported]) {
        [videoConnection setVideoOrientation:videoOrientation];
    }
    
    if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
        [self.captureSession setSessionPreset:AVCaptureSessionPreset1280x720];
    }
    
    [self.captureSession commitConfiguration];
    
    return YES;
}

- (void) startCaptureSession
{
    if ( !self.captureSession )
        return;
    
    if (!self.captureSession.isRunning )
        [self.captureSession startRunning];
}

- (void) stopCaptureSession
{
    [self.captureSession stopRunning];
}
#pragma mark - face deleagte
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    ASF_CAMERA_DATA* cameraData = [Utility getCameraDataFromSampleBuffer:sampleBuffer];
    NSArray *arrayFaceInfo = [self.videoProcessor process:cameraData];
    dispatch_sync(dispatch_get_main_queue(), ^{
        
        [self.glView renderWithCVPixelBuffer:cameraFrame orientation:0 mirror:NO];
        
        if(self.arrayAllFaceRectView.count >= arrayFaceInfo.count)//隐藏人脸
        {
            for (NSUInteger face=arrayFaceInfo.count; face<self.arrayAllFaceRectView.count; face++) {
                faceRectView = [self.arrayAllFaceRectView objectAtIndex:face];
                faceRectView.hidden = YES;
            }
        }
        else
        {
            for (NSUInteger face=self.arrayAllFaceRectView.count; face<arrayFaceInfo.count; face++) {
                UIStoryboard *faceRectStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                faceRectView = [faceRectStoryboard instantiateViewControllerWithIdentifier:@"FaceRectVC"].view;
                [self.view addSubview:faceRectView];
                [self.arrayAllFaceRectView addObject:faceRectView];
            }
        }
        
        for (NSUInteger face = 0; face < arrayFaceInfo.count; face++) {
            faceRectView = [self.arrayAllFaceRectView objectAtIndex:face];
            ASFVideoFaceInfo *faceInfo = [arrayFaceInfo objectAtIndex:face];
            faceRectView.hidden = NO;
            faceRectView.frame = [self dataFaceRect2ViewFaceRect:faceInfo.faceRect];
            
            // 判断是否是活体 并且状态正常
            CGRect faceInView = {0};
            faceInView = faceRectView.frame;
            // 2*π*150
            if (faceInView.size.width>AKT_FaceCircleW || faceInView.size.height>AKT_FaceCircleW || faceInView.origin.x<(SCREEN_WIDTH-AKT_FaceCircleW)/2 || faceInView.origin.y<140|| faceInView.origin.x>AKT_FaceCircleW+(SCREEN_WIDTH-AKT_FaceCircleW)/2 || faceInView.origin.y>140+AKT_FaceCircleW) {
                faceRectView.hidden = YES;
                NSLog(@"请将人脸放入有效区域");
            }else{// 人脸在有效区域内 偏航角不超过10°
                faceRectView.hidden = NO;
                if (faceInfo.face3DAngle.pitchAngle < AKT_Face3DAngle && faceInfo.face3DAngle.rollAngle < AKT_Face3DAngle && faceInfo.face3DAngle.yawAngle < AKT_Face3DAngle && faceInfo.face3DAngle.status == 0 && faceInfo.liveness == 1) { // 正常 活体
                    CIImage *image = [CIImage imageWithCVPixelBuffer:cameraFrame];
                    UIImage *imgF = [UIImage imageWithCIImage:image];// 获取到的原始图片
                    [self stopCaptureSession];
                 
                    
                    return;
                }else{
                    NSLog(@"请将正脸放在有效区域内");
                }
            }
            
        }
    });
    [Utility freeCameraData:cameraData];
}
#pragma mark -  dram rect
- (CGRect)dataFaceRect2ViewFaceRect:(MRECT)faceRect // 画框
{
    // 获取的图像的宽 高度
     CGFloat faceimgeW = faceRect.right-faceRect.left;
     CGFloat faceimgeH = faceRect.bottom-faceRect.top;
    
    // 视图的位置 大小
    CGRect frameGLView = self.glView.frame;
    
    // 计算后的人脸捕捉位置 大小
    CGRect frameFaceRect = {0};
    frameFaceRect.size.width = CGRectGetWidth(frameGLView)*faceimgeW/imgeWidth;
    frameFaceRect.size.height = CGRectGetHeight(frameGLView)*faceimgeH/imgeHight;
    frameFaceRect.origin.x = CGRectGetWidth(frameGLView)*faceRect.left/imgeWidth;
    frameFaceRect.origin.y = CGRectGetHeight(frameGLView)*faceRect.top/imgeHight;

    return frameFaceRect;
    
}

#pragma mark - animation
- (void)startAnimation{
CGAffineTransform endAngle = CGAffineTransformMakeRotation(angle * (M_PI / 180.0f));
[UIView animateWithDuration:0.03 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
 self.imgFaceC.transform = endAngle;
} completion:^(BOOL finished) {
    self->angle += 10;
    [self startAnimation];                  
}];

}
@end
