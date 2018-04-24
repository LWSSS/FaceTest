//
//  ViewController.m
//  FaceDemo
//
//  Created by liuwei on 2018/4/10.
//  Copyright © 2018年 lw_local. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate,UIAlertViewDelegate>{
    AVCaptureSession *_session;//执行输入设备和输出设备之间的数据传输
    AVCaptureDeviceInput *_captureInput;//对象输入流，
    AVCaptureStillImageOutput *_captureOutput;//图片的输出流对象，
    AVCaptureVideoPreviewLayer *_preview;//预览图层，来显示摄像机拍摄到的画面
    AVCaptureDevice *_device;//抽象的硬件设备;
}
@property (nonatomic, strong) UIView *cameraView;//底部视图
@property (nonatomic, strong) UIImageView *smalImage;//微笑图片
@property (nonatomic, strong) UIImageView *imageView;//显示摄像扑捉
@property (nonatomic, strong) CALayer *customLayer;//自定义涂成
@property (nonatomic, strong) UIImageView *sureImage;//确定扫描的图片
@property (nonatomic, strong) UIButton *changerCamer;//切换镜头
@property (nonatomic, strong) UIButton *startandstop;//开关

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"FaceTest";
    [self layoutsubview];
    
    [self initalize];
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)layoutsubview{
    self.cameraView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.cameraView.backgroundColor = [UIColor redColor];
    
    self.imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.cameraView];
    [self.view addSubview:self.imageView];
    
    self.changerCamer = [UIButton buttonWithType:UIButtonTypeCustom];
    
    self.changerCamer.frame = CGRectMake(20, self.cameraView.frame.origin.y+self.cameraView.frame.size.height+10, 40, 30);
    self.changerCamer.backgroundColor = [UIColor grayColor];
    [self.changerCamer setTitle:@"切换" forState:UIControlStateNormal];
    [self.changerCamer addTarget:self action:@selector(turnCamera:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.changerCamer];
    
    self.startandstop = [UIButton buttonWithType:UIButtonTypeCustom];
    self.startandstop.frame = CGRectMake(self.changerCamer.frame.size.width+self.changerCamer.frame.origin.x+20, self.changerCamer.frame.origin.y, 40, 30);
    [self.startandstop setTitle:@"关闭" forState:UIControlStateNormal];
    self.startandstop.backgroundColor = [UIColor grayColor];
    [self.startandstop addTarget:self action:@selector(start:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.startandstop];
    
    self.sureImage = [[UIImageView alloc] initWithFrame:CGRectMake(60, self.changerCamer.frame.origin.y+self.changerCamer.frame.size.height+20, self.view.frame.size.width-120, 100)];
    
    [self.view addSubview:self.sureImage];
}

-(void)initalize{
    //1创建会话层
    _session = [[AVCaptureSession alloc] init];
    [_session setSessionPreset:AVCaptureSessionPreset640x480];
    //创建配置输入设备
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *temdevice in devices) {
        if (temdevice.position == AVCaptureDevicePositionFront) {
            _captureInput = [AVCaptureDeviceInput deviceInputWithDevice:temdevice error:nil];
            
        }
    }
    NSError *error;
    if (!_captureInput) {
        NSLog(@"Error %@",error);
    }
    //把输入流添加到会话中
    [_session addInput:_captureInput];
    //out put 输出流
    AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
    captureOutput.alwaysDiscardsLateVideoFrames = YES;
    //创建线程对流
    
    dispatch_queue_t queue;
    queue = dispatch_queue_create("cameraQueue", NULL);
    
    [captureOutput setSampleBufferDelegate:self queue:queue];
    
    // dispatch_release(queue); arc下 不需要
    
    NSString *key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    NSNumber *value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
    
    [captureOutput setVideoSettings:videoSettings];
    [_session addOutput:captureOutput];
    //自定义涂成 加滤镜
    
    self.customLayer = [CALayer layer];
    self.customLayer.frame = self.view.bounds;
    self.customLayer.transform = CATransform3DRotate(CATransform3DIdentity, M_PI/2.0f, 0, 0, 1);
    
    
    self.customLayer.contentsGravity = kCAGravityResizeAspectFill;
    
    [self.view.layer addSublayer:self.customLayer];
    
    //创建，配置输出
    _captureOutput = [[AVCaptureStillImageOutput alloc] init];
//    NSDictionary *outputSetting = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil nil];
    NSDictionary * outputSetting = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey , nil];
    [_captureOutput setOutputSettings:outputSetting];
    [_session addOutput:_captureOutput];
    
    _preview = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    _preview.frame = CGRectMake(0, 0, self.cameraView.frame.size.width, self.cameraView.frame.size.height);
    
    
    _preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    [self.cameraView.layer addSublayer:_preview];
    
    [_session startRunning];
}

-(UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    // 为媒体数据设置一个CMSampleBuffer的Core Video图像缓存对象
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // 锁定pixel buffer的基地址
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    // 得到pixel buffer的基地址
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    // 得到pixel buffer的行字节数
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // 得到pixel buffer的宽和高
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    // 创建一个依赖于设备的RGB颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // 用抽样缓存的数据创建一个位图格式的图形上下文（graphics context）对象
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // 根据这个位图context中的像素数据创建一个Quartz image对象
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // 解锁pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    // 释放context和颜色空间
    CGContextRelease(context); CGColorSpaceRelease(colorSpace);
    // 用Quartz image创建一个UIImage对象image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    // 释放Quartz image对象
    CGImageRelease(quartzImage);
    return (image);
}

#pragma mark -
#pragma mark AVCaptureSession delegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
   UIImage * largeImage = [self imageFromSampleBuffer:sampleBuffer];
    [self performSelectorOnMainThread:@selector(detectForFacesInUIImage:) withObject:(id)largeImage waitUntilDone:NO];
}

-(void)detectForFacesInUIImage:(UIImage*)facePicture{
    // 配置识别质量
    NSDictionary *param = [NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh forKey:CIDetectorAccuracy];
    
    // 创建人脸识别器
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:param];
    
    // 识别图片
    CIImage *ciImg = [CIImage imageWithCGImage:facePicture.CGImage];
    
    // 识别特征: 这里添加了眨眼和微笑
    // CIDetectorSmile 眼部的识别效果很差，很难识别出来
    NSDictionary *featuresParam = @{CIDetectorSmile: [NSNumber numberWithBool:true],
                                    CIDetectorEyeBlink: [NSNumber numberWithBool:true]};
    
    // 获取识别结果
    NSArray *resultArr = [detector featuresInImage:ciImg options:featuresParam];
    
    UIView *resultView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    [self.view addSubview:resultView];
    if (resultArr.count <= 0) {
        NSLog(@"未检测到人脸");
        return;
    }
    for (CIFaceFeature *feature in resultArr) {
        
//        NSLog(@"微笑：%d", feature.hasSmile);
//        NSLog(@"右眼：%d", feature.rightEyeClosed);
//        NSLog(@"左眼：%d", feature.leftEyeClosed);
//        NSLog(@"脸框：%d", feature.hasFaceAngle);
//        NSLog(@"嘴：%d", feature.hasMouthPosition);
        
        if (feature.leftEyeClosed == YES || feature.rightEyeClosed == YES) {
            NSLog(@"检测到眨眼");
        }
        if (feature.hasSmile) {
            NSLog(@"检测到微笑");
        }
        /**
         关于feature中的position需要注意的是:
         position是以所要识别图像的原始尺寸为标准；
         因此，
         如果装载图片的UIImageView的尺寸与图片原始尺寸不一样的话，会出现识别的位置有偏差。
         */
        UIView *faceView = [[UIView alloc] initWithFrame:feature.bounds];
        faceView.layer.borderColor = [UIColor redColor].CGColor;
        faceView.layer.borderWidth = 1;
        [resultView addSubview:faceView];
        
        // 坐标系的转换
        [resultView setTransform:CGAffineTransformMakeScale(1, -1)];
        
        // 左眼
        if (feature.hasLeftEyePosition) {
            UIView * leftEyeView = [[UIView alloc] initWithFrame:CGRectMake(0, 30, 20, 20)];
            [leftEyeView setCenter:feature.leftEyePosition];
            leftEyeView.layer.borderWidth = 1;
            leftEyeView.layer.borderColor = [UIColor greenColor].CGColor;
            [resultView addSubview:leftEyeView];
        }
        
        // 右眼
        if (feature.hasRightEyePosition) {
            UIView * rightEyeView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
            [rightEyeView setCenter:feature.rightEyePosition];
            rightEyeView.layer.borderWidth = 1;
            rightEyeView.layer.borderColor = [UIColor redColor].CGColor;
            [resultView addSubview:rightEyeView];
        }
        
        // 嘴部
        if (feature.hasMouthPosition) {
            UIView * mouthView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
            [mouthView setCenter:feature.mouthPosition];
            mouthView.layer.borderWidth = 1;
            mouthView.layer.borderColor = [UIColor redColor].CGColor;
            [resultView addSubview:mouthView];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
