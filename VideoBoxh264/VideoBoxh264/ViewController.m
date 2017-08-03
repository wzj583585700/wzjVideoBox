

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>


@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>

@property(nonatomic,strong)UILabel *cLabel;
//
@property(nonatomic,strong)AVCaptureSession *cCapturesession;@property(nonatomic,strong)AVCaptureDeviceInput *cCaptureDeviceInput;//捕zuo
@property(nonatomic,strong)AVCaptureVideoDataOutput *cCaptureDataOutput;//数据输出口
@property(nonatomic,strong)AVCaptureVideoPreviewLayer *cPreviewLayer;

@end

@implementation ViewController
{
    int  frameID;//帧id
    dispatch_queue_t cCaptureQueue;//buzuoduilie
    dispatch_queue_t cEncodeQueue;//biammaduilie
    VTCompressionSessionRef cEncodeingSession;
    CMFormatDescriptionRef format;
    NSFileHandle *fileHandele;//写到沙河
    
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //基础UI实现
    _cLabel = [[UILabel alloc]initWithFrame:CGRectMake(20, 20, 200, 100)];
    _cLabel.text = @"cc课堂之H.264硬编码";
    _cLabel.textColor = [UIColor redColor];
    [self.view addSubview:_cLabel];
    
    UIButton *cButton = [[UIButton alloc]initWithFrame:CGRectMake(200, 20, 100, 100)];
    [cButton setTitle:@"play" forState:UIControlStateNormal];
    [cButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [cButton setBackgroundColor:[UIColor orangeColor]];
    [cButton addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cButton];
    

    
}


-(void)buttonClick:(UIButton *)button
{
    
    if (!_cCapturesession || !_cCapturesession.isRunning ) {
        
        [button setTitle:@"Stop" forState:UIControlStateNormal];
        [self startCapture];
        
        
    }else
    {
        [button setTitle:@"Play" forState:UIControlStateNormal];
        [self stopCapture];
    }
    
}

//开始捕捉<avfoubction里面的东西>
- (void)startCapture
{
    //初始化会话 
    self.cCapturesession = [[AVCaptureSession alloc]init];
    
    //设置捕捉分辨率
    self.cCapturesession.sessionPreset = AVCaptureSessionPreset640x480;
    
    cCaptureQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    cEncodeQueue  = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    AVCaptureDevice *inputCamera = nil;
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {

        if ([device position] == AVCaptureDevicePositionBack) {
            
            inputCamera = device;
        }
    }
    
    
    self.cCaptureDeviceInput = [[AVCaptureDeviceInput alloc]initWithDevice:inputCamera error:nil];//包装一下
    
    //捕捉会话能否加入
    if ([self.cCapturesession canAddInput:self.cCaptureDeviceInput]) {
        
        [self.cCapturesession addInput:self.cCaptureDeviceInput];
        
        
    }
    
    self.cCaptureDataOutput = [[AVCaptureVideoDataOutput alloc]init];

    [self.cCaptureDataOutput setAlwaysDiscardsLateVideoFrames:NO];
    
    //设置
    [self.cCaptureDataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    
    //输出队列
    [self.cCaptureDataOutput setSampleBufferDelegate:self queue:cCaptureQueue];
    
    if ([self.cCapturesession canAddOutput:self.cCaptureDataOutput]) {
        
        [self.cCapturesession addOutput:self.cCaptureDataOutput];
    }
    
    //连接方向
    AVCaptureConnection *connection = [self.cCaptureDataOutput connectionWithMediaType:AVMediaTypeVideo];
    
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    
    self.cPreviewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.cCapturesession];

    [self.cPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    
    [self.cPreviewLayer setFrame:self.view.bounds];
    
    [self.view.layer addSublayer:self.cPreviewLayer];
    
    NSString *filePath = [NSHomeDirectory()stringByAppendingPathComponent:@"/Documents/cc_video.h264"];

    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    
    BOOL createFile = [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
    if (!createFile) {
        
        NSLog(@"create file failed");
    }else
    {
        NSLog(@"create file success");

    }
    
    NSLog(@"filePaht = %@",filePath);
    fileHandele = [NSFileHandle fileHandleForWritingAtPath:filePath];
    
    
    //初始化videoToolbBox配置硬编码
    [self initVideoToolBox];
    
    //开始捕捉
    [self.cCapturesession startRunning];
    
    
    
    
}


//停止捕捉
- (void)stopCapture
{
    
    [self.cCapturesession stopRunning];
    
    [self.cPreviewLayer removeFromSuperlayer];
    
    [self endVideoToolBox];
    
    [fileHandele closeFile];
    
    fileHandele = NULL;
    
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    //
    dispatch_sync(cEncodeQueue, ^{
        [self encode:sampleBuffer];
    });
    
}



//初始化videoToolBox
-(void)initVideoToolBox
{
   dispatch_sync(cEncodeQueue, ^{
       frameID =0;
       int width = 480,height = 640;
       /*
        1 分配器 null 默认分配
        2 宽度
        3 高度
        4编码类型 h264
        5 null 编码规范 videoToolbox自行选择
        6 null 源像素缓存区
        7 null 压缩数据分配器
        8 回调
        */
       OSStatus status = VTCompressionSessionCreate(NULL, width, height, kCMVideoCodecType_H264, NULL, NULL, NULL, didCompressH264, (__bridge void*)(self), &cEncodeingSession);
       NSLog(@"H264: VTCompressionSessionCreate:%d ",status);
       if (status != 0) {
           NSLog(@"h264:Unabel create a h264 session ");
           return ;
       }
       
       //peizhi
       //设置实时编码
       VTSessionSetProperty(cEncodeingSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
       VTSessionSetProperty(cEncodeingSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Baseline_AutoLevel);
       //设置关键帧(GOPSize)间隔，GOP太小的话图像会模糊
       int  frameInterval = 10;
       //frameInterval转换为CFNumberRef
       CFNumberRef frameIntervalRaf = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &frameInterval);
       VTSessionSetProperty(cEncodeingSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, frameIntervalRaf);
       
       //设置期望征率 不是实际帧率
       
       int fps = 10;
       CFNumberRef fpsRef =CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType,&fps);
       
       VTSessionSetProperty(cEncodeingSession, kVTCompressionPropertyKey_ExpectedFrameRate, fpsRef);
       
       
       //设置码率（）码率越大视频越清晰，但文件也会变大
       //码率上线
       int bitRat  = width *height * 3*4 *8;
       CFNumberRef  bitTateRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &bitRat);
       VTSessionSetProperty(cEncodeingSession, kVTCompressionPropertyKey_AverageBitRate, bitTateRef);
       
       //码率均值 先把bitRatLimit包装成CFNumberRef类型
       int bitRatLimit = width * height *3*4;
       CFNumberRef bitRatLimitRef = CFNumberCreate(kCFAllocatorDefault,kCFNumberSInt32Type, &bitRatLimit);
       VTSessionSetProperty(cEncodeingSession, kVTCompressionPropertyKey_DataRateLimits, bitRatLimitRef);
       
       
       //开始编码
       VTCompressionSessionPrepareToEncodeFrames(cEncodeingSession);
   });
}


//编码
- (void) encode:(CMSampleBufferRef )sampleBuffer
{
    //拿到每一帧未编码数据

    CVImageBufferRef imageBuffer = (CVImageBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    //设置帧时间，如果不设置时间轴过长
    CMTime presentionTimeStamp = CMTimeMake(frameID++, 1000);
    VTEncodeInfoFlags flags;
    /*
     1 编码回话变量
     2  准备编码的数据编码数据
     3 时间搓，每一个传给cEncodeingSession都会大于上一个
     4
     */
    OSStatus statusCode =  VTCompressionSessionEncodeFrame(cEncodeingSession, imageBuffer, presentionTimeStamp, kCMTimeInvalid, NULL, NULL, &flags);
    if (statusCode != noErr) {
        VTCompressionSessionInvalidate(cEncodeingSession);
        CFRelease(cEncodeingSession);
        cEncodeingSession = NULL;
        return;
    }
}


//编码完成回调
/*
  1 h264编码完成后
 
 2 将编码成功的CMSampleBufferTef 转换成h264码流 通过网络传输
 3  解析SPS & PPS 组装码 nalu
 */
void didCompressH264(void *outputCallbackRefCon, void *sourceFrameRefCon, OSStatus status, VTEncodeInfoFlags infoFlags, CMSampleBufferRef sampleBuffer)
{
    //状态错误
    if (status != 0) {
        return;
    }
    if (!CMSampleBufferDataIsReady(sampleBuffer)) {
        NSLog(@"didCompressH264 data in not read");
        return;
    }
    ViewController *encode =(__bridge ViewController*)outputCallbackRefCon;
    //判断当前是否为关键帧
    bool keyFrame = !CFDictionaryContainsKey((CFArrayGetValueAtIndex(CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true), 0)),kCMSampleAttachmentKey_NotSync);
    if (keyFrame) {
        //图像存储方式
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        //sps pps
        size_t sparmerSetSize ,sparameterSetcount;
        const uint8_t *sparmeterSet;
        OSStatus statuCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &sparmeterSet, &sparmerSetSize, &sparameterSetcount, 0);
        if (statuCode == noErr) {
          size_t pparmerSetSize ,pparameterSetcount;
        
            const uint8_t *pparmeterSet;
            OSStatus statuCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &pparmeterSet, &pparmerSetSize, &pparameterSetcount, 0);
            if(statuCode == noErr)
            {
                
                NSData *sps = [NSData dataWithBytes:sparmeterSet length:sparmerSetSize];
                 NSData *pps = [NSData dataWithBytes:pparmeterSet length:pparmerSetSize];
                if(encode)
                {
                    [encode gotSpsPps:sps pps:pps];
                }
            }
            
      }
        
    }
    
    CMBlockBufferRef databufer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t length,totalLength;
    char *dataPointere;
    OSStatus statusCodeRaf = CMBlockBufferGetDataPointer(databufer, 0, &length, &totalLength, &dataPointere);
    if (statusCodeRaf == noErr) {
        size_t bufferOfferset =0;
        static const int AVVCCHeaderLenth = 4;
        while (bufferOfferset < totalLength -AVVCCHeaderLenth) {
            uint32_t NALUnitLength =0;
            memcmp(&NALUnitLength, dataPointere +bufferOfferset, AVVCCHeaderLenth) ;
            //从大端模式转换系统模式
            NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);
            //获取nalu数据
            NSData *data = [[NSData alloc] initWithBytes:(dataPointere + bufferOfferset + AVVCCHeaderLenth) length:NALUnitLength];
            //将nalu数据写入到文件(这就是推流的地方)
            [encode gotEncodedData:data isKeyFrame:keyFrame];
            
            //读取下一个nalu,一次回调可能包含多个nalu数据
            bufferOfferset += AVVCCHeaderLenth + NALUnitLength;
            
            
        
        }
    }
}

- (void)gotSpsPps:(NSData*)sps pps:(NSData*)pps
{
    
    const char bytes[] ="x00\x00\x00\x01";
    size_t length = sizeof(bytes)-1;
    NSData *byteHeader = [NSData dataWithBytes:bytes length:length];
    [fileHandele writeData:byteHeader];
    [fileHandele writeData:sps];
    [fileHandele writeData:byteHeader];
    [fileHandele writeData:pps];
}


- (void)gotEncodedData:(NSData*)data isKeyFrame:(BOOL)isKeyFrame
{
    if (fileHandele != NULL) {
        /*
         nalu 0x 000001 0000001 0x0000003
         H264 2种打包格式：
          annex-b byte steam format
         */
        const char bytes[] ="\x00\x00\x00\x01";
        //长度
        size_t length = sizeof(bytes)-1;
        NSData *byteHeader = [NSData dataWithBytes:bytes length:length];
        [fileHandele writeData:byteHeader];
        [fileHandele writeData:data];
       
       
    }
}

//结束VideoToolBox
-(void)endVideoToolBox
{
    VTCompressionSessionCompleteFrames(cEncodeingSession, kCMTimeInvalid);
    VTCompressionSessionInvalidate(cEncodeingSession);
    CFRelease(cEncodeingSession);
    cEncodeingSession = NULL;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition *)posion
{
    //获取可用的视频设备
   NSArray *array = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in array) {
        if (device.position == posion) {
            return device;
        }
    }
    return nil;
}

@end
