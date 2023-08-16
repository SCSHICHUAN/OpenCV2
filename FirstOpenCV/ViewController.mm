//
//  ViewController.m
//  FirstOpenCV
//
//  Created by Stan on 2023/8/12.
//

#import "ViewController.h"
#import "openCV.hpp"
#import <SceneKit/SceneKit.h>


@interface ViewController ()<V2TXLivePlayerObserver>
{
    CALayer *_videoLayer;
    int i ;
    SCNNode *_shapeNode;
    SCNSphere *_sphere;
    SCNMatrix4 _modelViewMatrix1;
    SCNMatrix4 _modelViewMatrix2;
    BOOL createOneframe;
    int64_t frames;
    CVPixelBufferRef pixelBuffer;
    UIImage *imgFrame;
}
@property(nonatomic,strong)UIImageView *imgv;

@property (weak, nonatomic) IBOutlet UISlider *sider;
@property (weak, nonatomic) IBOutlet UISlider *sider2;

@end

@implementation ViewController

-(UIImageView *)imgv{
    if(!_imgv){
        _imgv = [[UIImageView alloc] initWithFrame:CGRectMake(10, 40, 400, 200)];
    }
    return _imgv;
}

- (V2TXLivePlayer *)player{
    if(_player == nil){
        _player =[[V2TXLivePlayer alloc]init];
        [_player setRenderFillMode:V2TXLiveFillModeFill];
        [_player enableObserveVideoFrame:YES pixelFormat:V2TXLivePixelFormatBGRA32 bufferType:V2TXLiveBufferTypePixelBuffer];
        [_player enableObserveAudioFrame:YES];
        [_player setObserver:self];
    }
    return _player;
}


//视频帧无限回调
- (void)onRenderVideoFrame:(id<V2TXLivePlayer>)player frame:(V2TXLiveVideoFrame *)videoFrame{
    
    if (!createOneframe) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            CVPixelBufferRef  buffer = videoFrame.pixelBuffer;
            self->frames++;
            self->createOneframe = YES;
            
            cv::Mat mat = unfold_fish_eye_image(buffer);
            UIImage *matImg = [self UIImageFromCVMat:mat];
            UIImage *addHeightImg = [self addImageWatermark:matImg];
            self->_sphere.firstMaterial.diffuse.contents = addHeightImg;
            
            
            NSLog(@"creat frames:%lld",self->frames);
            self->createOneframe = NO;
        });
       
    }
   
}


- (cv::Mat) matFromImageBuffer: (CVImageBufferRef) buffer {

    cv::Mat mat ;

    CVPixelBufferLockBaseAddress(buffer, 0);

    void *address = CVPixelBufferGetBaseAddress(buffer);
    int width = (int) CVPixelBufferGetWidth(buffer);
    int height = (int) CVPixelBufferGetHeight(buffer);

    mat   = cv::Mat(height, width, CV_8UC4, address, 0);
//    cv::cvtColor(mat, mat, cv::COLOR_BGR2RGB);

    CVPixelBufferUnlockBaseAddress(buffer, 0);

    return mat;
}


- (CVImageBufferRef) getImageBufferFromMat: (cv::Mat) mat {

    cv::cvtColor(mat, mat, cv::COLOR_BGR2BGRA);

    int width = mat.cols;
    int height = mat.rows;

    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                              [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             [NSNumber numberWithInt:width], kCVPixelBufferWidthKey,
                             [NSNumber numberWithInt:height], kCVPixelBufferHeightKey,
                             nil];

    CVPixelBufferRef imageBuffer;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorMalloc, width, height, kCVPixelFormatType_32BGRA, (CFDictionaryRef) CFBridgingRetain(options), &imageBuffer) ;


    NSParameterAssert(status == kCVReturnSuccess && imageBuffer != NULL);

    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    void *base = CVPixelBufferGetBaseAddress(imageBuffer) ;
    memcpy(base, mat.data, mat.total()*4);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);

    return imageBuffer;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    i = 0;
    NSString *urlStr = @"https://media-pull-stream.hellobike.com/live/5000200096_112.live.flv";
    [self.player startLivePlay:urlStr];

    
//    cv::Mat mat = unfold_fish_eye_image([self pixelBufferFromCGImage:[self addImageWatermark:[UIImage imageNamed:@"a"]].CGImage]);

    
    [self configOneFrame];
    [self.view bringSubviewToFront:self.sider];
    [self.view bringSubviewToFront:self.sider2];
    
    self.sider.transform = CGAffineTransformMakeRotation(M_PI_2);
    frames = 0;
}






-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    cv::cvtColor(cvMat, cvMat, cv::COLOR_BGR2RGB);
    
  NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
  CGColorSpaceRef colorSpace;
  if (cvMat.elemSize() == 1) {
      colorSpace = CGColorSpaceCreateDeviceGray();
  } else {
      colorSpace = CGColorSpaceCreateDeviceRGB();
  }
  CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
  // Creating CGImage from cv::Mat
  CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                     cvMat.rows,                                 //height
                                     8,                                          //bits per component
                                     8 * cvMat.elemSize(),                       //bits per pixel
                                     cvMat.step[0],                            //bytesPerRow
                                     colorSpace,                                 //colorspace
                                      kCGImageAlphaNone||kCGBitmapByteOrderDefault,// bitmap info
                                     provider,                                   //CGDataProviderRef
                                     NULL,                                       //decode
                                     false,                                      //should interpolate
                                     kCGRenderingIntentDefault                   //intent
                                     );
  // Getting UIImage from CGImage
  UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
  CGImageRelease(imageRef);
  CGDataProviderRelease(provider);
  CGColorSpaceRelease(colorSpace);
  return finalImage;
 }




///截图打水印
-(UIImage *)addImageWatermark:(UIImage *)image{
    
    //获取视频资源的尺寸
    CGSize size = image.size;
    
    //创建父layer
    CALayer *parentLayer = [CALayer layer];
    parentLayer.frame=CGRectMake(0, 0, size.width, size.height*2);
    parentLayer.backgroundColor=[UIColor blackColor].CGColor;
    
    
    //生成视频图层
    //准备layer为参数，这个决定视频的大小
    CALayer *videoLayer=[CALayer layer];
    videoLayer.frame=CGRectMake(0, 0, size.width, size.height);
    videoLayer.contents = (__bridge id _Nullable)(image.CGImage);
    [parentLayer addSublayer:videoLayer];

    
    
    //生层图片
    UIImage *imageRet;
    UIGraphicsBeginImageContextWithOptions(parentLayer.bounds.size, NO, 0.0);
    [parentLayer renderInContext:UIGraphicsGetCurrentContext()];
    imageRet = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    videoLayer.contents = nil;//会导致内存爆增
    parentLayer = nil;
    videoLayer = nil;
    image = nil;
    
    
    return imageRet;
}



/// image => PixelBuffer
//- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image {
//    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
//                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
//                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
//                             nil];
//    
//    CVPixelBufferRef pxbuffer = NULL;
//    
//    CGFloat frameWidth = CGImageGetWidth(image);
//    CGFloat frameHeight = CGImageGetHeight(image);
//    
//    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,frameWidth,frameHeight,kCVPixelFormatType_32BGRA,(__bridge CFDictionaryRef) options, &pxbuffer);
//    
//    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
//    
//    CVPixelBufferLockBaseAddress(pxbuffer, 0);
//    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
//    NSParameterAssert(pxdata != NULL);
//    
//    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
//    CGContextRef context = CGBitmapContextCreate(pxdata, frameWidth, frameHeight, 8,CVPixelBufferGetBytesPerRow(pxbuffer),rgbColorSpace,(CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
//    
//    NSParameterAssert(context);
//    CGContextConcatCTM(context, CGAffineTransformIdentity);
//    CGContextDrawImage(context, CGRectMake(0, 0,frameWidth,frameHeight),  image);
//    
//    
//    CGColorSpaceRelease(rgbColorSpace);
//    CGContextRelease(context);
//    
//    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
//    
//    return pxbuffer;
//}


-(void)configOneFrame{
    SCNView *scViewLeft = [[SCNView alloc] initWithFrame:self.view.bounds];
    scViewLeft.backgroundColor = [UIColor blackColor];
    scViewLeft.antialiasingMode = SCNAntialiasingModeMultisampling4X;
    
    SCNScene *scene  = [SCNScene scene];
    scViewLeft.scene = scene;
   
    [self.view addSubview: scViewLeft];
    
    
    SCNNode *cameraNode = [SCNNode node];
    cameraNode.camera = [SCNCamera camera];
    [scene.rootNode addChildNode:cameraNode];
    
    
    SCNSphere *sphere = [SCNSphere sphereWithRadius:1.0];
//    sphere.segmentCount = 100;
    SCNNode *shapeNode = [SCNNode nodeWithGeometry:sphere];
//    shapeNode.geometry.firstMaterial.diffuse.wrapT = SCNWrapModeClamp;
//    shapeNode.geometry.firstMaterial.diffuse.wrapS = SCNWrapModeClamp;
    shapeNode.geometry.firstMaterial.cullMode = SCNCullFront;
    shapeNode.geometry.firstMaterial.doubleSided = false; // 设置只渲染一个表面
    sphere.firstMaterial.diffuse.contents = [UIImage imageNamed:@"aa.jpg"];
    cameraNode.position = SCNVector3Make(0, 0, 1.5);
    cameraNode.camera.usesOrthographicProjection = NO;
    
    
    
    
    cameraNode.camera.zNear = 0.01f;
    cameraNode.camera.zFar  = 100.0f;
    shapeNode.castsShadow = NO;
    shapeNode.position = SCNVector3Make(0, 0, 0);
    [scene.rootNode addChildNode:shapeNode];
    
    _sphere = sphere;
    _shapeNode = shapeNode;
    
    
    
    SCNMatrix4 modelViewMatrix = SCNMatrix4Identity;
    modelViewMatrix = SCNMatrix4Rotate(modelViewMatrix, -0.4 * 2 * M_PI, 1, 0, 0);
    _shapeNode.transform = modelViewMatrix;
    _modelViewMatrix2 = _modelViewMatrix1 = modelViewMatrix;
    
}

- (IBAction)slider:(UISlider *)sender {
    
    SCNMatrix4 modelViewMatrix = _modelViewMatrix2;
    modelViewMatrix = SCNMatrix4Rotate(modelViewMatrix,   sender.value * 2 * M_PI, 1, 0, 0);
    _shapeNode.transform = modelViewMatrix;
    _modelViewMatrix1 = modelViewMatrix;
    NSLog(@"%f",sender.value);
    
}

- (IBAction)slider2:(UISlider *)sender {
    
    SCNMatrix4 modelViewMatrix = _modelViewMatrix1;
    modelViewMatrix = SCNMatrix4Rotate(modelViewMatrix,   sender.value * 2 * M_PI, 0, 1, 0);
    _shapeNode.transform = modelViewMatrix;
    _modelViewMatrix2 = modelViewMatrix;
}

@end
