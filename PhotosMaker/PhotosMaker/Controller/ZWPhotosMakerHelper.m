//
//  ZWPhotosMakerHelper.m
//  ZWMusicPlayer
//
//  Created by Darsky on 2018/1/27.
//  Copyright © 2018年 Darsky. All rights reserved.
//

#import "ZWPhotosMakerHelper.h"
#import <AVFoundation/AVFoundation.h>
#import "ZWPhotosMakerAssetModel.h"

#define videoFrame 1
#define frameSize   3


@interface ZWPhotosMakerHelper()
{
}
@property (copy, nonatomic) NSString *videoPath;
@property (copy, nonatomic) NSString *musicName;
@property (copy, nonatomic) NSString *title;
@property (strong, nonatomic) AVAssetWriter *videoWriter;
@property (strong, nonatomic) AVAssetWriterInput *videoWriterInput;
@property (strong, nonatomic) AVAssetWriterInputPixelBufferAdaptor *adaptor;
@property (nonatomic) CGSize videoSize;

@end


@implementation ZWPhotosMakerHelper


- (BOOL)setupVideoWriter {

    NSString *documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    self.videoPath = [documents stringByAppendingPathComponent:@"video.mp4"];
    
    [[NSFileManager defaultManager] removeItemAtPath:self.videoPath
                                               error:nil];
    
    NSError *error;
    
    // Configure videoWriter
    NSURL *fileUrl = [NSURL fileURLWithPath:self.videoPath];
    self.videoWriter = [[AVAssetWriter alloc] initWithURL:fileUrl fileType:AVFileTypeMPEG4 error:&error];
    NSParameterAssert(self.videoWriter);
    
    // Configure videoWriterInput
    NSDictionary *videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:_videoSize.width * _videoSize.height], AVVideoAverageBitRateKey, nil];
    
    NSDictionary *videoSettings = @{AVVideoCodecKey: AVVideoCodecH264,
                                    AVVideoWidthKey: @(_videoSize.width),
                                    AVVideoHeightKey: @(_videoSize.height),
                                    AVVideoCompressionPropertiesKey: videoCompressionProps};
    
    self.videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                               outputSettings:videoSettings];
    
    NSParameterAssert(self.videoWriterInput);
    self.videoWriterInput.expectsMediaDataInRealTime = YES;
    NSDictionary *bufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
    
    self.adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.videoWriterInput
                                                                                    sourcePixelBufferAttributes:bufferAttributes];
    
    // add input
    [self.videoWriter addInput:self.videoWriterInput];
    [self.videoWriter startWriting];
    [self.videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    return YES;
}

- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    CGFloat frameWidth = CGImageGetWidth(image);
    CGFloat frameHeight = CGImageGetHeight(image);
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, frameWidth,
                                          frameHeight, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, frameWidth,
                                                 frameHeight, 8, CVPixelBufferGetBytesPerRow(pxbuffer), rgbColorSpace,
                                                 kCGImageAlphaPremultipliedFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, CGRectMake(0, 0, frameWidth,
                                           frameHeight), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

- (void)createAnimationWithImages:(NSInteger)imageCount
{
    AVMutableComposition *avMutableComposition = [AVMutableComposition composition];
    AVMutableCompositionTrack *avMutableCompositionTrack = [avMutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                                             preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *auMutableCompositionTrack = [avMutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                                             preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableVideoComposition *avMutableVideoComposition = [AVMutableVideoComposition videoComposition];
    avMutableVideoComposition.renderSize = _videoSize;
    avMutableVideoComposition.renderScale = 1.0;
    avMutableVideoComposition.frameDuration = CMTimeMake(1, 30);
    AVAsset *avAsset = [AVAsset assetWithURL:[NSURL fileURLWithPath:self.videoPath]];
    CMTime assetTime = [avAsset duration];
    Float64 duration = CMTimeGetSeconds(assetTime);
    AVAssetTrack *avAssetTrack = nil;
    NSError *error = nil;
    CMTime currentDuration = avMutableComposition.duration;
    avAssetTrack = [[avAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    if ([avMutableCompositionTrack insertTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0, 24),
                                                                    CMTimeMakeWithSeconds(duration, 24))
                                           ofTrack:avAssetTrack
                                            atTime:currentDuration
                                             error:&error])
    {
//        avMutableCompositionTrack.preferredTransform = avAssetTrack.preferredTransform;
        CALayer *parentLayer = [CALayer layer];
        CALayer *videoLayer = [CALayer layer];
        parentLayer.frame = CGRectMake(0, 0, _videoSize.width, _videoSize.height);
        videoLayer.frame = CGRectMake(0, 0, _videoSize.width, _videoSize.height);
        [parentLayer setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_videoMaker"]].CGColor];
        [parentLayer addSublayer:videoLayer];
        NSString *audioPath = [[NSBundle mainBundle] pathForResource:self.musicName
                                                              ofType:nil];
        AVAsset *auAsset = [AVAsset assetWithURL:[NSURL fileURLWithPath:audioPath]];
        
        CMTime auAssetTime = [auAsset duration];
        Float64 audioDuration = CMTimeGetSeconds(auAssetTime);
        
        AVAssetTrack *auAssetTrack = nil;
        auAssetTrack = [[auAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        if ([auMutableCompositionTrack insertTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0, videoFrame),
                                                                        CMTimeMakeWithSeconds(duration+3, videoFrame))
                                               ofTrack:auAssetTrack
                                                atTime:kCMTimeZero
                                                 error:&error])
        {
//            auMutableCompositionTrack.preferredTransform = auAssetTrack.preferredTransform;
        }
        
        for (int x = 0; x<imageCount; x++)
        {
            if (x== 0)
            {
                [self addBeginAnimationForLayer:videoLayer
                               withPartentLayer:parentLayer];
            }
            else
            {
                [self createKeyFrameAnimationsForLayer:videoLayer
                                       withParentLayer:parentLayer
                                               AtIndex:x
                                             andIsLast:(x==imageCount-1)?YES:NO];
            }
        }
        [self addEndAnimationForLayer:parentLayer
                              atIndex:imageCount];

        avMutableVideoComposition.animationTool = [AVVideoCompositionCoreAnimationTool
                                                   videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer
                                                   inLayer:parentLayer];
        
        AVMutableVideoCompositionInstruction *avMutableVideoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        
        [avMutableVideoCompositionInstruction setTimeRange:CMTimeRangeMake(kCMTimeZero, [avMutableComposition duration])];
        
        AVMutableVideoCompositionLayerInstruction *avMutableVideoCompositionLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:avMutableCompositionTrack];
        [avMutableVideoCompositionLayerInstruction setTransform:avMutableCompositionTrack.preferredTransform
                                                         atTime:kCMTimeZero];
        
        avMutableVideoCompositionInstruction.layerInstructions = [NSArray arrayWithObject:avMutableVideoCompositionLayerInstruction];
        avMutableVideoComposition.instructions = [NSArray arrayWithObject:avMutableVideoCompositionInstruction];
        
        
        NSString *documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL* saveLocationURL = [[NSURL alloc] initFileURLWithPath:[NSString stringWithFormat:@"%@/result.mp4", documents]];
        if ([fileManager fileExistsAtPath:saveLocationURL.relativePath])
        {
            [fileManager removeItemAtURL:saveLocationURL
                                   error:nil];
        }
        
        AVAssetExportSession *avAssetExportSession = [[AVAssetExportSession alloc] initWithAsset:avMutableComposition
                                                                                      presetName:AVAssetExportPresetHighestQuality];
        __block AVAssetExportSession *assetExportSession = avAssetExportSession;
        [avAssetExportSession setVideoComposition:avMutableVideoComposition];
        [avAssetExportSession setOutputURL:saveLocationURL];
        [avAssetExportSession setOutputFileType:AVFileTypeMPEG4];
        [avAssetExportSession setShouldOptimizeForNetworkUse:NO];
        [avAssetExportSession exportAsynchronouslyWithCompletionHandler:^(void)
         {
             switch (avAssetExportSession.status)
             {
                 case AVAssetExportSessionStatusFailed:
                 {
                     NSLog(@"exporting failed %@",[avAssetExportSession error]);
                     if (self.errorMsgBlock != nil)
                     {
                         self.errorMsgBlock([[avAssetExportSession error] localizedDescription]);
                     }
                 }
                     break;
                 case AVAssetExportSessionStatusCompleted:
                 {
                     NSLog(@"exporting completed");
                     // 想做什么事情在这个
                     assetExportSession = nil;
                     if (self.finishBlock != nil)
                     {
                         self.finishBlock(saveLocationURL);
                     }
                 }
                     break;
                 case AVAssetExportSessionStatusCancelled:
                 {
                     NSLog(@"export cancelled");
                     if (self.errorMsgBlock != nil)
                     {
                         self.errorMsgBlock(@"export cancelled");
                     }
                 }
                     break;
                 default:
                     break;
             }
         }];
    }
}

- (void)createKeyFrameAnimationsForLayer:(CALayer*)layer
                         withParentLayer:(CALayer*)parentLayer
                                 AtIndex:(NSInteger)index
                              andIsLast:(BOOL)isLast
{
    int animationType = arc4random()%5;
    if (animationType == 0)
    {
        [self addShowAnimationForLayer:layer AtIndex:index];
        CAKeyframeAnimation * animation;
        animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
        animation.duration = 1.0f;
        //animation.delegate = self;
        animation.removedOnCompletion = NO;
        animation.autoreverses = YES;
        animation.fillMode = kCAFillModeForwards;
        NSArray *values = @[[NSNumber numberWithFloat:1],
                            [NSNumber numberWithFloat:1.2],
                            [NSNumber numberWithFloat:1.4],
                            [NSNumber numberWithFloat:1.5]];
        animation.values = values;
        animation.beginTime = index*frameSize+0.5;
        [layer addAnimation:animation
                     forKey:nil];
    }
    else if (animationType == 1)
    {
        [self addShowAnimationForLayer:layer AtIndex:index];
        CAKeyframeAnimation * animation;
        animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation"];
        animation.duration = 1.0f;
        //animation.delegate = self;
        animation.removedOnCompletion = NO;
        animation.autoreverses = YES;
        animation.fillMode = kCAFillModeForwards;
        NSArray *values = @[[NSNumber numberWithFloat:0],
                            [NSNumber numberWithFloat:(1.0 * M_PI)],
                            [NSNumber numberWithFloat:(1.5 * M_PI)],
                            [NSNumber numberWithFloat:(2.0 * M_PI)]];
        animation.values = values;
        animation.beginTime = index*frameSize+0.5;
        [layer addAnimation:animation
                     forKey:nil];
    }
    else if (animationType == 2)
    {
        [self addShowAnimationForLayer:layer AtIndex:index];
        CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
        animation.duration = 1.0f;
        animation.removedOnCompletion = NO;
        animation.autoreverses = YES;
        animation.fillMode = kCAFillModeForwards;
        animation.values = @[@(0),@(-100),@(-150),@(-200)];
        animation.beginTime = index*frameSize+0.5;
        [layer addAnimation:animation
                     forKey:nil];
    }
    else if (animationType == 3)
    {
        [self addShowAnimationForLayer:layer AtIndex:index];
        [self createGifAnimationForLayer:layer
                                 atIndex:index];
    }
    else
    {
        [self addShowAnimationForLayer:layer AtIndex:index];
        CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
        animation.duration = 1.0f;
        animation.removedOnCompletion = NO;
        animation.autoreverses = YES;
        animation.fillMode = kCAFillModeForwards;
        animation.values = @[@(0),@(100),@(150),@(200)];
        animation.beginTime = index*frameSize+0.5;
        [layer addAnimation:animation
                     forKey:nil];
    }
    CAKeyframeAnimation * animation;
    animation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    animation.duration = 0.5;
    //animation.delegate = self;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    NSArray *values = @[[NSNumber numberWithFloat:1.0],
                        [NSNumber numberWithFloat:0.8],
                        [NSNumber numberWithFloat:0.4],
                        [NSNumber numberWithFloat:0.2]];
    animation.values = isLast?@[[NSNumber numberWithFloat:1.0],
                                [NSNumber numberWithFloat:0.6],
                                [NSNumber numberWithFloat:0.3],
                                [NSNumber numberWithFloat:0.0]]:values;
    animation.beginTime = index*frameSize+2.5;
    [layer addAnimation:animation
                 forKey:nil];
}

- (void)addShowAnimationForLayer:(CALayer*)targetLayer
                         AtIndex:(NSInteger)index
{
    CAKeyframeAnimation * beginAnimation;
    beginAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    beginAnimation.duration = 0.5f;
    //animation.delegate = self;
    beginAnimation.removedOnCompletion = NO;
    beginAnimation.fillMode = kCAFillModeForwards;
    beginAnimation.values = @[[NSNumber numberWithFloat:0.0],
                              [NSNumber numberWithFloat:0.2],
                              [NSNumber numberWithFloat:0.4],
                              [NSNumber numberWithFloat:0.8],
                              [NSNumber numberWithFloat:1.0]];
    beginAnimation.beginTime = index*frameSize;
    [targetLayer addAnimation:beginAnimation
                       forKey:nil];
}

- (void)addBeginAnimationForLayer:(CALayer*)targetLayer
                 withPartentLayer:(CALayer*)parentLayer
{
    targetLayer.opacity = 0;
    
    CALayer *beginAnimationLayer = [CALayer layer];
    
    UIImage *animationImage =  [self createTextImageForContext:self.title?:@"课堂时光鸡"];
    [beginAnimationLayer setContents:(id)[animationImage CGImage]];
    beginAnimationLayer.frame = CGRectMake(_videoSize.width/2-animationImage.size.width/2.0, -_videoSize.height, animationImage.size.width, animationImage.size.height);
    beginAnimationLayer.opacity = 1;
    [beginAnimationLayer setMasksToBounds:YES];
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"];
    animation.duration = 0.5f;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.values = @[@(-_videoSize.height),
                         @(-_videoSize.height/2.0),
                         @(0),
                         @(_videoSize.height/2.0),
                         @(_videoSize.height)];
    animation.beginTime = AVCoreAnimationBeginTimeAtZero;
    [beginAnimationLayer addAnimation:animation
                               forKey:nil];
    
    CAKeyframeAnimation *anim = [CAKeyframeAnimation animation];
    anim.keyPath = @"transform.rotation";
    anim.values = @[@(0),@(-5/180.0 * M_PI),@(5/180.0 * M_PI),@(-5/180.0 * M_PI),@(5/180.0 * M_PI),@(0)];
    anim.removedOnCompletion = NO;
    anim.duration = 1.0;
    anim.fillMode = kCAFillModeForwards;
    anim.beginTime = 1.5f;
    [beginAnimationLayer addAnimation:anim forKey:nil];
    
    CAKeyframeAnimation * animationEnd;
    animationEnd = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    animationEnd.duration = 0.5f;
    //animation.delegate = self;
    animationEnd.removedOnCompletion = NO;
    animationEnd.fillMode = kCAFillModeForwards;
    animationEnd.values = @[[NSNumber numberWithFloat:1.0],
                            [NSNumber numberWithFloat:0.0]];
    animationEnd.beginTime = 2.5;
    [beginAnimationLayer addAnimation:animationEnd
                forKey:nil];
    
    [parentLayer addSublayer:beginAnimationLayer];
}

- (void)addEndAnimationForLayer:(CALayer*)targetLayer
                        atIndex:(NSInteger)index
{
    [self addEndAnimationForLayer:targetLayer
                      atBeginTime:index*frameSize];
}

- (void)addEndAnimationForLayer:(CALayer*)targetLayer
                    atBeginTime:(float)beginTime
{
    CALayer *endAnimationLayer = [CALayer layer];
    
    UIImage *animationImage = [UIImage imageNamed:@"end_logo"];
    [endAnimationLayer setContents:(id)[animationImage CGImage]];
    endAnimationLayer.frame = CGRectMake(_videoSize.width/2-animationImage.size.width/2.0, _videoSize.height/2- animationImage.size.height/2.0, animationImage.size.width, animationImage.size.height);
    endAnimationLayer.opacity = 0;
    [endAnimationLayer setMasksToBounds:YES];
    
    
    CAKeyframeAnimation * animation;
    animation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    animation.duration = 1;
    //animation.delegate = self;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.values = @[[NSNumber numberWithFloat:0.0],
                         [NSNumber numberWithFloat:0.3],
                         [NSNumber numberWithFloat:0.5],
                         [NSNumber numberWithFloat:0.7],
                         [NSNumber numberWithFloat:1.0]];
    animation.beginTime = beginTime+0.5;
    [endAnimationLayer addAnimation:animation
                             forKey:nil];
    CAKeyframeAnimation *anim = [CAKeyframeAnimation animation];
    anim.keyPath = @"transform.rotation";
    anim.values = @[@(0),@(-5/180.0 * M_PI),@(5/180.0 * M_PI),@(-5/180.0 * M_PI),@(5/180.0 * M_PI),@(0)];
    anim.removedOnCompletion = NO;
    anim.duration = 1;
    anim.fillMode = kCAFillModeForwards;
    anim.beginTime = beginTime+1.5;
    [endAnimationLayer addAnimation:anim forKey:nil];
    [targetLayer addSublayer:endAnimationLayer];
}


-(NSMutableArray *)praseGIFDataToImageArray:(NSData *)data;
{
    NSMutableArray *frames = [[NSMutableArray alloc] init];
    CGImageSourceRef src = CGImageSourceCreateWithData((CFDataRef)data, NULL);
    CGFloat animationTime = 0.f;
    if (src) {
        size_t l = CGImageSourceGetCount(src);
        frames = [NSMutableArray arrayWithCapacity:l];
        for (size_t i = 0; i < l; i++) {
            CGImageRef img = CGImageSourceCreateImageAtIndex(src, i, NULL);
            NSDictionary *properties = (NSDictionary *)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(src, i, NULL));
            NSDictionary *frameProperties = [properties objectForKey:(NSString *)kCGImagePropertyGIFDictionary];
            NSNumber *delayTime = [frameProperties objectForKey:(NSString *)kCGImagePropertyGIFUnclampedDelayTime];
            animationTime += [delayTime floatValue];
            if (img) {
                [frames addObject:[UIImage imageWithCGImage:img]];
                CGImageRelease(img);
            }
        }
        CFRelease(src);
    }
    return frames;
}

- (void)createGifAnimationForLayer:(CALayer*)layer
                           atIndex:(NSInteger)index
{
    CALayer *endAnimationLayer = [CALayer layer];
    endAnimationLayer.frame = CGRectMake(0, 0, _videoSize.width, _videoSize.height);
    endAnimationLayer.opacity = 0.5;
    [endAnimationLayer setMasksToBounds:YES];
    
    CAKeyframeAnimation * shinningAnimation;
    shinningAnimation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
    shinningAnimation.duration = 2.5f;
    //animation.delegate = self;
    shinningAnimation.removedOnCompletion = NO;
    shinningAnimation.fillMode = kCAFillModeForwards;
    NSString *gifPath = [[NSBundle mainBundle] pathForResource:@"shining.gif"
                                                        ofType:nil];
    NSMutableArray *gifImages = [self praseGIFDataToImageArray:[NSData dataWithContentsOfURL:[NSURL fileURLWithPath:gifPath]]];
    NSMutableArray *values =[NSMutableArray array];
    for (int x = 0; x<gifImages.count; x++)
    {
        UIImage *tempImage = gifImages[x];
        [values addObject:(__bridge UIImage*)tempImage.CGImage];
    }
    shinningAnimation.values = values;
    shinningAnimation.beginTime = index*frameSize;
    [endAnimationLayer addAnimation:shinningAnimation
                             forKey:nil];
    
    CAKeyframeAnimation * animationEnd;
    animationEnd = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    animationEnd.duration = 0.5f;
    //animation.delegate = self;
    animationEnd.removedOnCompletion = NO;
    animationEnd.fillMode = kCAFillModeForwards;
    animationEnd.values = @[[NSNumber numberWithFloat:0.5],
                            [NSNumber numberWithFloat:0.0]];
    animationEnd.beginTime = index*frameSize+2.5;
    [endAnimationLayer addAnimation:animationEnd
                             forKey:nil];
    
    [layer addSublayer:endAnimationLayer];
}

- (UIImage *)createTextImageForContext:(NSString *)text
{
    UIGraphicsBeginImageContextWithOptions(_videoSize, NO, 0.0);
    //获得 图形上下文
    CGContextRef context=UIGraphicsGetCurrentContext();
    CGContextDrawPath(context, kCGPathStroke);
    CGFloat nameFont = (_videoSize.width-40)/(float)text.length;
    //画 自己想要画的内容
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont systemFontOfSize:nameFont],
                                 NSForegroundColorAttributeName:[UIColor whiteColor]};
    CGRect sizeToFit = [text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, nameFont) options:NSStringDrawingUsesDeviceMetrics attributes:attributes context:nil];
    NSLog(@"sizeToFit: %f %f",sizeToFit.size.width,sizeToFit.size.height);
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    [text drawAtPoint:CGPointMake((_videoSize.width-sizeToFit.size.width)/2,(_videoSize.height-sizeToFit.size.height)/2) withAttributes:attributes];
    //返回绘制的新图形
    
    UIImage *newImage=UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage*)createClipImage:(UIImage*)image
{
    UIImage *borderImage = [UIImage imageNamed:@"videMaker_border"];
    UIGraphicsBeginImageContext(image.size);
    CGContextRef gc = UIGraphicsGetCurrentContext();
    
    CGContextMoveToPoint(gc, 178.5, 94.5);
    CGContextAddLineToPoint(gc, 87.5, 433.5);
    CGContextAddLineToPoint(gc, 424.5, 523.5);
    CGContextAddLineToPoint(gc, 515.5, 186.5);
    CGContextAddLineToPoint(gc, 178.5, 94.5);
    CGContextClosePath(gc);
    CGContextClip(gc);
    
    CGContextTranslateCTM(gc, 0, image.size.height);
    CGContextScaleCTM(gc, 1, -1);
    CGContextDrawImage(gc, CGRectMake(0, 0, image.size.width, image.size.height), [image CGImage]);
    CGContextDrawImage(gc, CGRectMake(0, 0, borderImage.size.width, borderImage.size.height), [borderImage CGImage]);
    //结束绘画
    UIImage *destImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return destImg;
//
//    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
//    [bezierPath moveToPoint: CGPointMake(178.5, 94.5)];
//    [bezierPath addLineToPoint: CGPointMake(87.5, 433.5)];
//    [bezierPath addLineToPoint: CGPointMake(424.5, 523.5)];
//    [bezierPath addLineToPoint: CGPointMake(515.5, 186.5)];
//    [bezierPath addLineToPoint: CGPointMake(178.5, 94.5)];
//    [bezierPath closePath];
//    [UIColor.grayColor setFill];
//    [bezierPath fill];
//    [UIColor.blackColor setStroke];
//    bezierPath.lineWidth = 1;
//    [bezierPath stroke];
}
//根据 CAAnimationGroup 生成视频
- (void)startMakePhotoVideosWithAnimationGroup:(CAAnimationGroup*)group
                                     withMusic:(NSString*)musicName
                                       forSize:(CGSize)videoSize
                               withFinishBlock:(PhotosMakeFinishBlock)photosMakeFinishBlock
                              adnErrorMsgBlock:(ErrorMsgBlock)errorMsgBlock
{
    if (musicName == nil)
    {
        self.musicName = @"What Is Love.mp3";
    }
    else
    {
        self.musicName = musicName;
    }
    self.videoSize = videoSize;
    self.finishBlock = photosMakeFinishBlock;
    self.errorMsgBlock = errorMsgBlock;
    if (self.videoWriter == nil && [self setupVideoWriter])
    {
        dispatch_queue_t dispatchQueue = dispatch_queue_create("mediaInputQueue", NULL);
        int __block frame = 0;

        float duration = group.duration;
        UIImage *emptyImage = [self createImageWithColor:[UIColor whiteColor]];
        CVPixelBufferRef buffer = [self pixelBufferFromCGImage:emptyImage.CGImage];
        [self.videoWriterInput requestMediaDataWhenReadyOnQueue:dispatchQueue
                                                     usingBlock:^
         {
             while ([self.videoWriterInput isReadyForMoreMediaData])
             {
                 if(![self.adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeMake(frame, (int32_t)1)])
                 {
                     NSError *error = self.videoWriter.error;
                     if(error)
                     {
                         NSLog(@"Unresolved error %@,%@.", error, [error userInfo]);
                         if (self.errorMsgBlock != nil)
                         {
                             self.errorMsgBlock([error localizedDescription]);
                             CVPixelBufferRelease(buffer);
                             break;
                         }
                     }
                 }
                 if(++frame >= (int)duration)
                 {
                     CVPixelBufferRelease(buffer);
                     [self.videoWriterInput markAsFinished];
                     [self.videoWriter finishWritingWithCompletionHandler:^{
                         [self createPhotoVideosWithAnimationGroup:group];
                         self.adaptor = nil;
                         self.videoWriterInput = nil;
                         self.videoWriter = nil;
                     }];
                     break;
                 }
             }
         }];
    }
  
}

- (void)createPhotoVideosWithAnimationGroup:(CAAnimationGroup*)group
{
    AVMutableComposition *avMutableComposition = [AVMutableComposition composition];
    AVMutableCompositionTrack *avMutableCompositionTrack = [avMutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                                             preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *auMutableCompositionTrack = [avMutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                                             preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableVideoComposition *avMutableVideoComposition = [AVMutableVideoComposition videoComposition];
    avMutableVideoComposition.renderSize = _videoSize;
    avMutableVideoComposition.renderScale = 1.0;
    avMutableVideoComposition.frameDuration = CMTimeMake(1, 30);
    AVAsset *avAsset = [AVAsset assetWithURL:[NSURL fileURLWithPath:self.videoPath]];
    CMTime assetTime = [avAsset duration];
    Float64 duration = CMTimeGetSeconds(assetTime);
    AVAssetTrack *avAssetTrack = nil;
    NSError *error = nil;
    CMTime currentDuration = avMutableComposition.duration;
    avAssetTrack = [[avAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    if ([avMutableCompositionTrack insertTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0, 24),
                                                                   CMTimeMakeWithSeconds(duration, 24))
                                           ofTrack:avAssetTrack
                                            atTime:currentDuration
                                             error:&error])
    {
        CALayer *parentLayer = [CALayer layer];
        CALayer *videoLayer = [CALayer layer];
        parentLayer.frame = CGRectMake(0, 0, _videoSize.width, _videoSize.height);
        videoLayer.frame = CGRectMake(0, 0, _videoSize.width, _videoSize.height);
        [parentLayer setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_videoMaker"]].CGColor];
        [parentLayer addSublayer:videoLayer];
        NSString *audioPath = [[NSBundle mainBundle] pathForResource:self.musicName
                                                              ofType:nil];
        AVAsset *auAsset = [AVAsset assetWithURL:[NSURL fileURLWithPath:audioPath]];
        
        CMTime auAssetTime = [auAsset duration];
        Float64 audioDuration = CMTimeGetSeconds(auAssetTime);
        
        AVAssetTrack *auAssetTrack = nil;
        auAssetTrack = [[auAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        if ( [auMutableCompositionTrack insertTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0, videoFrame),
                                                                        CMTimeMakeWithSeconds(duration+3, videoFrame))
                                                ofTrack:auAssetTrack
                                                 atTime:kCMTimeZero
                                                  error:&error])
        {
            //            auMutableCompositionTrack.preferredTransform = auAssetTrack.preferredTransform;
        }
        group.beginTime = AVCoreAnimationBeginTimeAtZero;
        [videoLayer addAnimation:group forKey:nil];
        [self addEndAnimationForLayer:parentLayer
                          atBeginTime:duration];
        
        avMutableVideoComposition.animationTool = [AVVideoCompositionCoreAnimationTool
                                                   videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer
                                                   inLayer:parentLayer];
        
        AVMutableVideoCompositionInstruction *avMutableVideoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        
        [avMutableVideoCompositionInstruction setTimeRange:CMTimeRangeMake(kCMTimeZero, [avMutableComposition duration])];
        
        AVMutableVideoCompositionLayerInstruction *avMutableVideoCompositionLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:avMutableCompositionTrack];
        [avMutableVideoCompositionLayerInstruction setTransform:avMutableCompositionTrack.preferredTransform
                                                         atTime:kCMTimeZero];
        
        avMutableVideoCompositionInstruction.layerInstructions = [NSArray arrayWithObject:avMutableVideoCompositionLayerInstruction];
        avMutableVideoComposition.instructions = [NSArray arrayWithObject:avMutableVideoCompositionInstruction];
        
        
        NSString *documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL* saveLocationURL = [[NSURL alloc] initFileURLWithPath:[NSString stringWithFormat:@"%@/result.mp4", documents]];
        if ([fileManager fileExistsAtPath:saveLocationURL.relativePath])
        {
            [fileManager removeItemAtURL:saveLocationURL
                                   error:nil];
        }
        __weak CAAnimationGroup *weakgroup = group;
        __block AVMutableComposition *targetMutableComposition = avMutableComposition;

        AVAssetExportSession *avAssetExportSession = [[AVAssetExportSession alloc] initWithAsset:avMutableComposition
                                                                                      presetName:AVAssetExportPresetMediumQuality];
        [avAssetExportSession setVideoComposition:avMutableVideoComposition];
        [avAssetExportSession setOutputURL:saveLocationURL];
        [avAssetExportSession setOutputFileType:AVFileTypeMPEG4];
        [avAssetExportSession setShouldOptimizeForNetworkUse:NO];
        [avAssetExportSession exportAsynchronouslyWithCompletionHandler:^(void)
         {
             switch (avAssetExportSession.status)
             {
                 case AVAssetExportSessionStatusFailed:
                 {
                     NSLog(@"exporting failed %@",[avAssetExportSession error]);
                     if (self.errorMsgBlock != nil)
                     {
                         self.errorMsgBlock([[avAssetExportSession error] localizedDescription]);
                     }
                 }
                     break;
                 case AVAssetExportSessionStatusCompleted:
                 {
                     NSLog(@"exporting completed");
                     // 想做什么事情在这个
                     weakgroup.animations = nil;
                     targetMutableComposition = nil;
                     if (self.finishBlock != nil)
                     {
                         self.finishBlock(saveLocationURL);
                     }
                 }
                     break;
                 case AVAssetExportSessionStatusCancelled:
                 {
                     NSLog(@"export cancelled");
                     if (self.errorMsgBlock != nil)
                     {
                         self.errorMsgBlock(@"export cancelled");
                     }
                 }
                     break;
                 default:
                     break;
             }
         }];
    }
}

- (UIImage*)createImageWithColor:(UIColor*)color
{
    CGRect rect=CGRectMake(0.0f, 0.0f, self.videoSize.width, self.videoSize.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return theImage;
}

- (void)dealloc
{
    if (self.videoWriter)
    {
        self.adaptor = nil;
        self.videoWriterInput = nil;
        self.videoWriter = nil;
    }
    self.finishBlock = nil;
    self.errorMsgBlock = nil;
}


@end
