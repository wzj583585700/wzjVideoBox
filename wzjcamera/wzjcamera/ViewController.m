//
//  ViewController.m
//  wzjcamera
//
//  Created by 魏志军 on 2017/8/3.
//  Copyright © 2017年 魏志军. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#define kScreenBounds   [UIScreen mainScreen].bounds
#define kScreenWidth  kScreenBounds.size.width*1.0
#define kScreenHeight kScreenBounds.size.height*1.0
@interface ViewController ()<AVCaptureMetadataOutputObjectsDelegate,UIAlertViewDelegate>
//捕获设备，通常是前置摄像头，后置摄像头，麦克风（音频输入）
@property(nonatomic)AVCaptureDevice *device;

//AVCaptureDeviceInput 代表输入设备，他使用AVCaptureDevice 来初始化
@property(nonatomic)AVCaptureDeviceInput *input;//捕捉的一个输入

//当启动摄像头开始捕获输入
@property(nonatomic)AVCaptureMetadataOutput *output;
//输出静态照片的输出端
@property (nonatomic)AVCaptureStillImageOutput *ImageOutPut;//捕捉图片的一个输出

//session：由他把输入输出结合在一起，并开始启动捕获设备（摄像头）
@property(nonatomic)AVCaptureSession *session;

//图像预览层，实时显示捕获的图像
@property(nonatomic,strong)AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic,strong)UIButton *PhotoButton;
@property (nonatomic,strong)UIButton *flashButton;
@property (nonatomic, strong)UIButton *rightButton;
@property (nonatomic,strong)UIImageView *imageView;
@property (nonatomic,strong)UIView *focusView;
@property (nonatomic,assign)BOOL isflashOn;
@property (nonatomic,strong)UIImage *image;

@property (nonatomic,assign)BOOL canCa;
@property (nonatomic, strong) UIView *contentView;


@property (nonatomic, copy)  NSString *name;
@property (nonatomic, copy)  NSString *outrequrepathpath;
@property (nonatomic, copy) NSString *takePhoto;
@property (nonatomic, assign) BOOL animt;
@property (nonatomic, copy) NSString *imagePath;
@end


@implementation ViewController


- (void)viewDidLoad {
        [super viewDidLoad];
        // Do any additional setup after loading the view.
   
        self.contentView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        
        [self.view addSubview:self.contentView];
    
    
        
        NSFileManager *fir = [NSFileManager defaultManager];
        [fir createDirectoryAtPath:self.imagePath withIntermediateDirectories:YES attributes:nil error:nil];
        NSString *requrepath  = [self.imagePath stringByAppendingPathComponent:_name];
        
        [fir createFileAtPath:requrepath contents:nil attributes:nil];
        self.outrequrepathpath = requrepath;
        
        //NSLog(@"=========%@",self.imagePath);
        
        _canCa = [self canUserCamear];
        if (_canCa) {
            [self customCamera];
            [self customUI];
            
        }else{
            return;
        }
    }
    - (void)customUI{
        
        
        _PhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _PhotoButton.frame = CGRectMake(kScreenWidth*1/2.0-30, kScreenHeight-100, 60, 60);
        [_PhotoButton setImage:[UIImage imageNamed:@"icon-photobotton"] forState: UIControlStateNormal];
        [_PhotoButton setImage:[UIImage imageNamed:@"icon-phontobotton-xuan"] forState:UIControlStateSelected];
        [_PhotoButton addTarget:self action:@selector(shutterCamera) forControlEvents:UIControlEventTouchUpInside];
        // [self.view addSubview:_PhotoButton];
        [self.contentView addSubview:_PhotoButton];
        _focusView = [[UIView alloc]initWithFrame:CGRectMake(kScreenWidth/2-50, kScreenHeight/2-50, 100, 100)];
        _focusView.layer.borderWidth = 1.0;
        _focusView.layer.borderColor =[UIColor greenColor].CGColor;
        _focusView.backgroundColor = [UIColor clearColor];
        //[self.view addSubview:_focusView];
        [self.contentView addSubview:_focusView];
        _focusView.hidden = NO;
        [UIView animateWithDuration:0.5 animations:^{
            //_focusView.transform = CGAffineTransformMakeScale(0.25, 0.25);
            _focusView.transform = CGAffineTransformScale(_focusView.transform, 1.25, 1.25);
        }completion:^(BOOL finished) {
            
            [UIView animateWithDuration:0.5 animations:^{
                _focusView.transform = CGAffineTransformScale(_focusView.transform, 0.5, 0.5);
                //_focusView.transform = CGAffineTransformIdentity;
            } completion:^(BOOL finished) {
                _focusView.hidden = YES;
            }];
        }];
        
        UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
        leftButton.frame = CGRectMake(10, 10, 60, 60);
        //[leftButton setTitle:@"取消" forState:UIControlStateNormal];
        [leftButton setImage:[UIImage imageNamed:@"cha"] forState:UIControlStateNormal];
        [leftButton setImage:[UIImage imageNamed:@"cha-xuan"] forState:UIControlStateSelected];
        leftButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        [leftButton addTarget:self action:@selector(cancle) forControlEvents:UIControlEventTouchUpInside];
        // [self.view addSubview:leftButton];
        [self.contentView addSubview:leftButton];
        UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        rightButton.frame = CGRectMake(kScreenWidth/2 +30, 10, 60, 60);
        //[rightButton setTitle:@"闪光灯关" forState:UIControlStateNormal];
        [rightButton setImage:[UIImage imageNamed:@"icon-jindengguan-xuan"] forState:UIControlStateNormal];
        [rightButton setImage:[UIImage imageNamed:@"icon-jindengguan"] forState:UIControlStateSelected];
        rightButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        //[rightButton addTarget:self action:@selector(changeCamera) forControlEvents:UIControlEventTouchUpInside];
        [rightButton addTarget:self action:@selector(FlashOn:) forControlEvents:UIControlEventTouchUpInside];
        //[self.view addSubview:rightButton];
        self.rightButton = rightButton;
        [self.contentView addSubview:rightButton];
        _flashButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        _flashButton.frame = CGRectMake(kScreenWidth/2+100, 10, 80, 60);
        //[_flashButton setTitle:@"切换" forState:UIControlStateNormal];
        [_flashButton setImage:[UIImage imageNamed:@"icon－photo"] forState:UIControlStateNormal];
        [_flashButton setImage:[UIImage imageNamed:@"icon－photo－xuan"] forState:UIControlStateSelected];
        //[_flashButton addTarget:self action:@selector(FlashOn) forControlEvents:UIControlEventTouchUpInside];
        [_flashButton addTarget:self action:@selector(changeCamera
                                                      ) forControlEvents:UIControlEventTouchUpInside];
        //[self.view addSubview:_flashButton];
        
        [self.contentView addSubview:_flashButton];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(focusGesture:)];
        [self.contentView addGestureRecognizer:tapGesture];
    }
    - (void)customCamera{
        self.contentView.backgroundColor = [UIColor whiteColor];
        
        //使用AVMediaTypeVideo 指明self.device代表视频，默认使用后置摄像头进行初始化
        self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        //使用设备初始化输入（将device包装成AVCaptureDeviceInput才能用）
        self.input = [[AVCaptureDeviceInput alloc]initWithDevice:self.device error:nil];
        
        //生成输出对象
        self.output = [[AVCaptureMetadataOutput alloc]init];
        self.ImageOutPut = [[AVCaptureStillImageOutput alloc] init];
        
        //生成会话，用来结合输入输出
        self.session = [[AVCaptureSession alloc]init];
        if ([self.session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
            
            //设置捕捉分辨率
            self.session.sessionPreset = AVCaptureSessionPreset1280x720;
            
        }
        //加入会话
        if ([self.session canAddInput:self.input]) {
            [self.session addInput:self.input];
        }
        
        //输出图片链接
        if ([self.session canAddOutput:self.ImageOutPut]) {
            [self.session addOutput:self.ImageOutPut];
        }
        
        //使用self.session，初始化预览层，self.session负责驱动input进行信息的采集，layer负责把图像渲染显示
        self.previewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.session];
        self.previewLayer.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        [self.contentView.layer addSublayer:self.previewLayer];
        
        //开始启动
        // [self.session startRunning];
        [self startSession];
        //如果该设备的后置摄像头有闪光灯
        if ([_device lockForConfiguration:nil]) {
            if ([_device isFlashModeSupported:AVCaptureFlashModeAuto]) {
                [_device setFlashMode:AVCaptureFlashModeAuto];
            }
            //自动白平衡
            if ([_device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
                [_device setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
            }
            [_device unlockForConfiguration];
        }
    }
    /*
     自己写的
     */
    - (void)startSession
    {
        if (![self.session isRunning]) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:@"show" forKey:@"eventType"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"show" object:nil userInfo:dict];
            //[self notifitionWithValue:@"show" name:@"show"];
            
            [self.session startRunning];
        }
    }
    - (void)FlashOn:(UIButton *)rightbutton{
        if ([_device lockForConfiguration:nil]) {
            if (_isflashOn) {
                if ([_device isFlashModeSupported:AVCaptureFlashModeOff]) {
                    [_device setFlashMode:AVCaptureFlashModeOff];
                    _isflashOn = NO;
                    //[_flashButton setTitle:@"闪光灯关" forState:UIControlStateNormal];
                    [rightbutton setImage:[UIImage imageNamed:@"icon-jindengguan-xuan"] forState:UIControlStateNormal];
                }
            }else{
                if ([_device isFlashModeSupported:AVCaptureFlashModeOn]) {
                    [_device setFlashMode:AVCaptureFlashModeOn];
                    _isflashOn = YES;
                    //[_flashButton setTitle:@"闪光灯开" forState:UIControlStateNormal];
                    [rightbutton setImage:[UIImage imageNamed:@"icon-jindeng开"] forState:UIControlStateNormal];
                }
            }
            
            [_device unlockForConfiguration];
        }
    }
    - (void)changeCamera{
        
        NSUInteger cameraCount = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
        if (cameraCount > 1) {
            NSError *error;
            
            CATransition *animation = [CATransition animation];
            
            animation.duration = .5f;
            
            animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            
            animation.type = @"oglFlip";
            AVCaptureDevice *newCamera = nil;
            AVCaptureDeviceInput *newInput = nil;
            AVCaptureDevicePosition position = [[_input device] position];
            if (position == AVCaptureDevicePositionFront){
                newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
                self.rightButton.hidden = NO;
                NSLog(@"=======nihao");
                animation.subtype = kCATransitionFromLeft;
            }
            else {
                newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
                self.rightButton.hidden = YES;
                NSLog(@"++++++++buhao");
                animation.subtype = kCATransitionFromRight;
            }
            
            newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
            [self.previewLayer addAnimation:animation forKey:nil];
            if (newInput != nil) {
                [self.session beginConfiguration];
                [self.session removeInput:_input];
                if ([self.session canAddInput:newInput]) {
                    [self.session addInput:newInput];
                    self.input = newInput;
                    
                } else {
                    [self.session addInput:self.input];
                }
                
                [self.session commitConfiguration];
                
            } else if (error) {
                NSLog(@"toggle carema failed, error = %@", error);
            }
            
        }
    }
    //定义一个方法，获取前置或后置的视频设备
    - (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position{
        NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for ( AVCaptureDevice *device in devices )
            if ( device.position == position ) return device;
        return nil;
    }
    - (void)focusGesture:(UITapGestureRecognizer*)gesture{
        //获取当前触摸的坐标
        CGPoint point = [gesture locationInView:gesture.view];
        [self focusAtPoint:point];
    }
    //对某个点进行聚焦
    - (void)focusAtPoint:(CGPoint)point{
        CGSize size = self.contentView.bounds.size;
        CGPoint focusPoint = CGPointMake(point.y /size.height ,1-point.x/size.width );
        NSError *error;
        //先锁定设备
        if ([self.device lockForConfiguration:&error]) {
            
            //修改属性
            if ([self.device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
                //设置自动对焦的方法
                [self.device setFocusPointOfInterest:focusPoint];
                [self.device setFocusMode:AVCaptureFocusModeAutoFocus];
            }
            
            if ([self.device isExposureModeSupported:AVCaptureExposureModeAutoExpose ]) {
                [self.device setExposurePointOfInterest:focusPoint];
                [self.device setExposureMode:AVCaptureExposureModeAutoExpose];
            }
            //设备解锁
            [self.device unlockForConfiguration];
            
            _focusView.center = point;
            _focusView.hidden = NO;
            [UIView animateWithDuration:0.3 animations:^{
                _focusView.transform = CGAffineTransformMakeScale(1.25, 1.25);
            }completion:^(BOOL finished) {
                [UIView animateWithDuration:0.5 animations:^{
                    _focusView.transform = CGAffineTransformIdentity;
                } completion:^(BOOL finished) {
                    _focusView.hidden = NO;
                }];
            }];
        }
        
    }
#pragma mark - 截取照片（定义捕捉静态照片的方法）
    - (void) shutterCamera
    {
        self.takePhoto = @"takePhoto";
        //获取拍照的AVCaptureConnection
        AVCaptureConnection * videoConnection = [self.ImageOutPut connectionWithMediaType:AVMediaTypeVideo];
        
        if (!videoConnection) {
            NSLog(@"take photo failed!");
            return;
        }
        
        //拍照并保存
        [self.ImageOutPut captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
            //如果图片缓存不为null
            if (imageDataSampleBuffer == NULL) {
                return;
            }
            NSData * imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            self.image = [UIImage imageWithData:imageData];
            [self.session stopRunning];
            NSData *imgData;
                       if (self.outrequrepathpath) {
                
                NSLog(@"self.outrqurepathpath%@",self.outrequrepathpath);
                
                [imgData writeToFile:self.outrequrepathpath atomically:YES];
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                [dict setValue:self.outrequrepathpath forKey:@"imagePath"];
                [dict setValue:self.takePhoto forKey:@"eventType"];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"wei" object:nil userInfo:dict];
                
            }
       
            
            
            [self.session startRunning];
            
            
            //        self.imageView = [[UIImageView alloc]initWithFrame:self.previewLayer.frame];
            //        [self.contentView insertSubview:_imageView belowSubview:_PhotoButton];
            //        self.imageView.layer.masksToBounds = YES;
            //        self.imageView.image = _image;
            //        NSLog(@"image size = %@",NSStringFromCGSize(self.image.size));
        }];
    }
#pragma - 保存至相册
    - (void)saveImageToPhotoAlbum:(UIImage*)savedImage
    {
        __block NSString *albumPathStr = @"ni";
        
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc]init];
        [library  writeImageToSavedPhotosAlbum:savedImage.CGImage orientation:(NSUInteger)savedImage.imageOrientation completionBlock:^(NSURL *assetURL, NSError *error) {
            if (error) {
                albumPathStr = @"undefined";
            } else{
                
                albumPathStr = [assetURL absoluteString];
            }
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:albumPathStr forKey:@"albumPath"];
            [dict setValue:self.takePhoto forKey:@"eventType"];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"albumPath" object:nil userInfo:dict];
        }];
        //    UIImageWriteToSavedPhotosAlbum(savedImage, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
        
    }
    // 指定回调方法
    /*
     - (void)image: (UIImage *) image didFinishSavingWithError: (NSError *) error contextInfo: (void *) contextInfo
     
     {
     NSString *msg = nil ;
     if(error != NULL){
     msg = @"保存图片失败" ;
     }else{
     msg = @"保存图片成功" ;
     }
     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"保存图片结果提示"
     message:msg
     delegate:self
     cancelButtonTitle:@"确定"
     otherButtonTitles:nil];
     [alert show];
     }
     */
    -(void)cancle{
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"close" forKey:@"eventType"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"cancle" object:nil userInfo:dict];
        //[self notifitionWithValue:@"close" name:@"cancle"];
        if (self.animt) {
            NSLog(@"yes");
        }else
        {
            NSLog(@"no");
        }
       // [self dismissViewControllerAnimated:self.animation completion:nil];
        //[self.contentView removeFromSuperview];
        /*
         [self.imageView removeFromSuperview];
         [self startSession];
         */
        //[self.session startRunning];
        //[self.session stopRunning];
    }
    - (void)notifitionWithValue:(NSString *)value name:(NSString *)name
    {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:value forKey:@"eventType"];
        [[NSNotificationCenter defaultCenter] postNotificationName:name object:nil userInfo:dict];
    }
#pragma mark - 检查相机权限
    - (BOOL)canUserCamear{
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (authStatus == AVAuthorizationStatusDenied) {
            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"请打开相机权限" message:@"设置-隐私-相机" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil];
            alertView.tag = 100;
            [alertView show];
            return NO;
        }
        else{
            return YES;
        }
        return YES;
    }
    - (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
        if (buttonIndex == 0 && alertView.tag == 100) {
            
            NSURL * url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            
            if([[UIApplication sharedApplication] canOpenURL:url]) {
                
                [[UIApplication sharedApplication] openURL:url];
                
            }
        }
    }
    

    







@end
