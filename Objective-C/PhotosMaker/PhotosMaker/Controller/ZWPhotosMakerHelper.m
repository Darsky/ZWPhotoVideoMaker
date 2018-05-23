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
#import "ZWPhotosNodeModel.h"


@interface ZWPhotosMakerHelper()
{
    UIImage *_emptyImage;
}
@property (copy, nonatomic) NSString *videoPath;
@property (strong, nonatomic) AVAssetWriter *videoWriter;
@property (strong, nonatomic) AVAssetWriterInput *videoWriterInput;
@property (strong, nonatomic) AVAssetWriterInputPixelBufferAdaptor *adaptor;
@property (nonatomic) CGSize videoSize;

@property (strong, nonatomic) NSMutableArray *defaultMusicArray;

@end


@implementation ZWPhotosMakerHelper

static const NSInteger kVideoFrame = 1;

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


- (void)startMakePhotoVideosWithAnimationGroup:(CAAnimationGroup*)group
                                     withNodes:(NSArray*)nodeArray
                                   withBgImage:(UIImage*)bgImage
                                      andMusic:(MusicFileModel*)musicModel
{
    if (self.videoWriter == nil && [self setupVideoWriter])
    {
        dispatch_queue_t dispatchQueue = dispatch_queue_create("mediaInputQueue", NULL);
        int __block frame = 0;
        
        float duration = group.duration;
        UIImage *emptyImage = [self createImageWithColor:[UIColor blackColor]];
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

                         [self createPhotoVideosWithAnimationGroup:group
                                                     withVideoNode:nodeArray
                                                       withBgImage:bgImage
                                                          andMusic:musicModel];
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

- (void)combinePicturesAndVideoByEmptyFileWithAnimationGroup:(CAAnimationGroup*)group
                                               withVideoNode:(NSArray*)nodeArray
                                                 withBgImage:(UIImage*)bgImage
                                                    andMusic:(MusicFileModel*)musicModel
                                                     forSize:(CGSize)videoSize
                                             withFinishBlock:(PhotosMakeFinishBlock)photosMakeFinishBlock
                                            andProgressBlock:(PhotosMakeProgressBlock)progressBlock
                                            adnErrorMsgBlock:(ErrorMsgBlock)errorMsgBlock
{
    self.videoSize = videoSize;
    self.finishBlock = photosMakeFinishBlock;
    self.progressBlock = progressBlock;
    self.errorMsgBlock = errorMsgBlock;
    if ([nodeArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.type == 1"]].count == 0)
    {
        [self startMakePhotoVideosWithAnimationGroup:group
                                           withNodes:nodeArray
                                         withBgImage:bgImage
                                            andMusic:musicModel];
        return;
    }
    NSTimeInterval totalDuration = 0;
    AVMutableComposition *resultComposition = [AVMutableComposition composition];
    AVMutableCompositionTrack * videoMutableCompositionTrack = nil;//视频合成轨道
    videoMutableCompositionTrack = [resultComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                  preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVMutableCompositionTrack *audioMutableCompositionTrack = nil;//音频合成轨道
    audioMutableCompositionTrack = [resultComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                  preferredTrackID:kCMPersistentTrackID_Invalid];
    
    
    //原视频 asset

    NSString *audioPath =[ [NSBundle mainBundle]  pathForResource:musicModel.fileName
                                                           ofType:@"mp3"];
    AVAsset *auAsset = [AVAsset assetWithURL:[NSURL fileURLWithPath:audioPath]];
    AVAssetTrack *oriAudioAssetTrack = [[auAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    CALayer *animationLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, _videoSize.width, _videoSize.height);
    videoLayer.frame = CGRectMake(0, 0, _videoSize.width, _videoSize.height);
    animationLayer.frame = CGRectMake(0, 0, _videoSize.width, _videoSize.height);
    [parentLayer setBackgroundColor:[UIColor colorWithPatternImage:bgImage].CGColor];
    [videoLayer setBackgroundColor:[UIColor colorWithPatternImage:bgImage].CGColor];
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:animationLayer];
    AVMutableVideoCompositionLayerInstruction *avMutableVideoCompositionLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoMutableCompositionTrack];
    NSMutableArray *instructions = [NSMutableArray array];
    NSError *error;
    NSMutableArray *videoLayerAnimations = [NSMutableArray array];
    CAAnimationGroup *videoGroup = [CAAnimationGroup animation];

    for (int x = 0; x<nodeArray.count; x++)
    {
        ZWPhotosNodeModel *nodeModel = nodeArray[x];
        totalDuration += nodeModel.duration;
        if (nodeModel.type == ZWPhotosNodeTypeVideo)
        {
            CAKeyframeAnimation * dissAnimation;
            dissAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
            dissAnimation.duration = 0.5;
            //animation.delegate = self;
            dissAnimation.removedOnCompletion = NO;
            dissAnimation.fillMode = kCAFillModeForwards;
            dissAnimation.values = @[[NSNumber numberWithFloat:1.0]];
            dissAnimation.beginTime = nodeModel.startTime;
            [videoLayerAnimations addObject:dissAnimation];
            AVAsset *insertAsset = nodeModel.object;
            AVAssetTrack *insertAssetTrack = [[insertAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            [videoMutableCompositionTrack insertTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0, kVideoFrame),
                                                                          CMTimeMakeWithSeconds(nodeModel.duration, kVideoFrame))
                                                  ofTrack:insertAssetTrack
                                                   atTime:CMTimeMakeWithSeconds(nodeModel.startTime, kVideoFrame)
                                                    error:&error];
            
            
            float scale = 1.0;
            
            if (nodeModel.isPortraitVideo)
            {
                if (nodeModel.degree == 90)
                {
                    scale = _videoSize.height/nodeModel.mediaWidth;
                    CGAffineTransform trans = CGAffineTransformMakeScale(scale, scale);
                    trans = CGAffineTransformRotate(trans, M_PI_2);
                    
                    trans = CGAffineTransformTranslate(trans, 0, -((float)_videoSize.width/scale/2.0+ nodeModel.mediaHeight/2.0));
                    
                    
                    [avMutableVideoCompositionLayerInstruction setTransform:trans
                                                                     atTime:CMTimeMakeWithSeconds(nodeModel.startTime, kVideoFrame)];
                }
                else if (nodeModel.degree == 270)
                {
                    scale = _videoSize.height/nodeModel.mediaWidth;
                    CGAffineTransform trans = CGAffineTransformMakeScale(scale, scale);
                    trans = CGAffineTransformRotate(trans, -M_PI_2);
                    
                    trans = CGAffineTransformTranslate(trans, -nodeModel.mediaWidth,((float)_videoSize.width/scale/2.0- nodeModel.mediaHeight/2.0));
                    
                    
                    [avMutableVideoCompositionLayerInstruction setTransform:trans
                                                                     atTime:CMTimeMakeWithSeconds(nodeModel.startTime, kVideoFrame)];
                }
                else
                {
                    scale = _videoSize.height/nodeModel.mediaHeight;
                    CGAffineTransform trans = CGAffineTransformMakeScale(scale, scale);
                    
                    trans = CGAffineTransformTranslate(trans,((float)_videoSize.width/scale/2.0- nodeModel.mediaWidth/2.0),0);
                    
                    
                    [avMutableVideoCompositionLayerInstruction setTransform:trans
                                                                     atTime:CMTimeMakeWithSeconds(nodeModel.startTime, kVideoFrame)];
                }
            }
            else
            {
                scale = _videoSize.width/nodeModel.mediaWidth;
                CGAffineTransform trans = CGAffineTransformMake(insertAssetTrack.preferredTransform.a*scale, insertAssetTrack.preferredTransform.b*scale, insertAssetTrack.preferredTransform.c*scale, insertAssetTrack.preferredTransform.d*scale, insertAssetTrack.preferredTransform.tx*scale, insertAssetTrack.preferredTransform.ty*scale);
                
                [avMutableVideoCompositionLayerInstruction setTransform:trans
                                                                 atTime:CMTimeMakeWithSeconds(nodeModel.startTime, kVideoFrame)];
            }
            //
            //            [avMutableVideoCompositionLayerInstruction setTransform:insertTransform
            //                                                             atTime:CMTimeMakeWithSeconds(nodeModel.startTime, videoFrame)];
            
        }
        else
        {
//            [videoMutableCompositionTrack insertTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(nodeModel.startTime, videoFrame),
//                                                                          CMTimeMakeWithSeconds(nodeModel.duration, videoFrame))
//                                                  ofTrack:oriVideoAssetTrack
//                                                   atTime:CMTimeMakeWithSeconds(nodeModel.startTime, videoFrame)
//                                                    error:&error];
            CAKeyframeAnimation * dissAnimation;
            dissAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
            dissAnimation.duration = nodeModel.duration;
            //animation.delegate = self;
            dissAnimation.removedOnCompletion = NO;
            dissAnimation.fillMode = kCAFillModeForwards;
            dissAnimation.values = @[[NSNumber numberWithFloat:0.0]];
            dissAnimation.beginTime = nodeModel.startTime;
            [videoLayerAnimations addObject:dissAnimation];
            [videoMutableCompositionTrack insertEmptyTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(nodeModel.startTime, kVideoFrame),
                                                                               CMTimeMakeWithSeconds(nodeModel.duration, kVideoFrame))];
            
            
            [avMutableVideoCompositionLayerInstruction setTransform:CGAffineTransformIdentity
                                                             atTime:CMTimeMakeWithSeconds(nodeModel.startTime, kVideoFrame)];
        }
    }
    [instructions addObject:avMutableVideoCompositionLayerInstruction];
    //插入音频
    if ( [audioMutableCompositionTrack insertTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0, kVideoFrame),
                                                                       CMTimeMakeWithSeconds(totalDuration, kVideoFrame))
                                               ofTrack:oriAudioAssetTrack
                                                atTime:kCMTimeZero
                                                 error:&error])
    {
        //            auMutableCompositionTrack.preferredTransform = auAssetTrack.preferredTransform;
    }
    
    group.beginTime = AVCoreAnimationBeginTimeAtZero;
    [animationLayer addAnimation:group forKey:nil];
    videoGroup.animations = videoLayerAnimations;
    videoGroup.duration = totalDuration;
    videoGroup.fillMode = kCAFillModeForwards;
    videoGroup.removedOnCompletion = NO;
    videoGroup.beginTime = AVCoreAnimationBeginTimeAtZero;
    [videoLayer addAnimation:videoGroup
                      forKey:nil];

    
    AVMutableVideoCompositionInstruction *avMutableVideoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    
    [avMutableVideoCompositionInstruction setTimeRange:CMTimeRangeMake(kCMTimeZero, [resultComposition duration])];
    
    
    avMutableVideoCompositionInstruction.layerInstructions = instructions;
    
    
    //插入视频处理
    AVMutableVideoComposition *avMutableVideoComposition = [AVMutableVideoComposition videoComposition];
    avMutableVideoComposition.renderSize = _videoSize;
    avMutableVideoComposition.frameDuration = CMTimeMake(1, 30);
    //avMutableVideoComposition.instructions = instructions;
    avMutableVideoComposition.instructions = [NSArray arrayWithObject:avMutableVideoCompositionInstruction];
    
    avMutableVideoComposition.animationTool = [AVVideoCompositionCoreAnimationTool
                                                               videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer
                                                               inLayer:parentLayer];
    
    NSString *documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL* saveLocationURL = [[NSURL alloc] initFileURLWithPath:[NSString stringWithFormat:@"%@/mixResult.mp4", documents]];
    if ([fileManager fileExistsAtPath:saveLocationURL.relativePath])
    {
        [fileManager removeItemAtURL:saveLocationURL
                               error:nil];
    }
    
    AVAssetExportSession *avAssetExportSession = [[AVAssetExportSession alloc] initWithAsset:resultComposition
                                                                                  presetName:AVAssetExportPresetHighestQuality];
    [avAssetExportSession setVideoComposition:avMutableVideoComposition];
    [avAssetExportSession setOutputURL:saveLocationURL];
    [avAssetExportSession setOutputFileType:AVFileTypeMPEG4];
    [avAssetExportSession setShouldOptimizeForNetworkUse:YES];
    [avAssetExportSession exportAsynchronouslyWithCompletionHandler:^(void)
     {
         switch (avAssetExportSession.status)
         {
             case AVAssetExportSessionStatusExporting:
             {
                 NSLog(@"exporting progress %.2f",avAssetExportSession.progress);
                 if (self.progressBlock != nil)
                 {
                     self.progressBlock(avAssetExportSession.progress);
                 }
             }
                 break;
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

- (void)createPhotoVideosWithAnimationGroup:(CAAnimationGroup*)group
                              withVideoNode:(NSArray*)videoArray
                                withBgImage:(UIImage*)bgImage
                                   andMusic:(MusicFileModel*)musicModel
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
        [parentLayer setBackgroundColor:[UIColor colorWithPatternImage:bgImage].CGColor];
        [parentLayer addSublayer:videoLayer];
        
        //插入音频
        NSString *audioPath =[ [NSBundle mainBundle]  pathForResource:musicModel.fileName
                                                               ofType:@"mp3"];
        AVAsset *auAsset = [AVAsset assetWithURL:[NSURL fileURLWithPath:audioPath]];
        
        CMTime auAssetTime = [auAsset duration];
        
        AVAssetTrack *auAssetTrack = nil;
        auAssetTrack = [[auAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        if ( [auMutableCompositionTrack insertTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0, kVideoFrame),
                                                                        CMTimeMakeWithSeconds(duration+3, kVideoFrame))
                                                ofTrack:auAssetTrack
                                                 atTime:kCMTimeZero
                                                  error:&error])
        {
            //            auMutableCompositionTrack.preferredTransform = auAssetTrack.preferredTransform;
        }
        
        group.beginTime = AVCoreAnimationBeginTimeAtZero;
        [videoLayer addAnimation:group forKey:nil];
        
        
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
                                                                                      presetName:AVAssetExportPresetHighestQuality];
        [avAssetExportSession setVideoComposition:avMutableVideoComposition];
        [avAssetExportSession setOutputURL:saveLocationURL];
        [avAssetExportSession setOutputFileType:AVFileTypeMPEG4];
        [avAssetExportSession setShouldOptimizeForNetworkUse:NO];
        [avAssetExportSession exportAsynchronouslyWithCompletionHandler:^(void)
         {
             switch (avAssetExportSession.status)
             {
                 case AVAssetExportSessionStatusExporting:
                 {
                     if (self.progressBlock != nil)
                     {
                         self.progressBlock(avAssetExportSession.progress);
                     }
                 }
                     break;
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
                     NSLog(@"生成原动画视频");
                     // 想做什么事情在这个
                     weakgroup.animations = nil;
                     targetMutableComposition = nil;
                     [self mixVideoForOrigin:saveLocationURL
                                   WithNodes:videoArray];
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

- (void)mixVideoForOrigin:(NSURL*)originVideoUrl
                WithNodes:(NSArray*)nodeArray
{
    AVMutableComposition *resultComposition = [AVMutableComposition composition];
    AVMutableCompositionTrack * videoMutableCompositionTrack = nil;//视频合成轨道
    videoMutableCompositionTrack = [resultComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                            preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVMutableCompositionTrack *audioMutableCompositionTrack = nil;//音频合成轨道
    audioMutableCompositionTrack = [resultComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                                             preferredTrackID:kCMPersistentTrackID_Invalid];
    
    
    //原视频 asset
    AVAsset *originAsset   = [AVAsset assetWithURL:originVideoUrl];
    CMTime originAssetTime = [originAsset duration];
    Float64 originAssetDuration = CMTimeGetSeconds(originAssetTime);
    AVAssetTrack *oriVideoAssetTrack = [[originAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVAssetTrack *oriAudioAssetTrack = [[originAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    CALayer *videoLayer = [CALayer layer];
    videoLayer.frame = CGRectMake(0, 0, _videoSize.width, _videoSize.height);
    

    AVMutableVideoCompositionLayerInstruction *avMutableVideoCompositionLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoMutableCompositionTrack];
    
    NSMutableArray *instructions = [NSMutableArray array];
    NSError *error;
    for (int x = 0; x<nodeArray.count; x++)
    {
        ZWPhotosNodeModel *nodeModel = nodeArray[x];
        
        if (nodeModel.type == ZWPhotosNodeTypeVideo)
        {
            AVAsset *insertAsset = nodeModel.object;
            AVAssetTrack *insertAssetTrack = [[insertAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            [videoMutableCompositionTrack insertTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0, kVideoFrame),
                                                CMTimeMakeWithSeconds(nodeModel.duration, kVideoFrame))
                                                  ofTrack:insertAssetTrack
                                                   atTime:CMTimeMakeWithSeconds(nodeModel.startTime, kVideoFrame)
                                                    error:&error];


            float scale = 1.0;

            if (nodeModel.isPortraitVideo)
            {
                if (nodeModel.degree == 90)
                {
                    scale = _videoSize.height/nodeModel.mediaWidth;
                    CGAffineTransform trans = CGAffineTransformMakeScale(scale, scale);
                    trans = CGAffineTransformRotate(trans, M_PI_2);
                    
                    trans = CGAffineTransformTranslate(trans, 0, -((float)_videoSize.width/scale/2.0+ nodeModel.mediaHeight/2.0));
                    
                    
                    [avMutableVideoCompositionLayerInstruction setTransform:trans
                                                                     atTime:CMTimeMakeWithSeconds(nodeModel.startTime, kVideoFrame)];
                }
                else if (nodeModel.degree == 270)
                {
                    scale = _videoSize.height/nodeModel.mediaWidth;
                    CGAffineTransform trans = CGAffineTransformMakeScale(scale, scale);
                    trans = CGAffineTransformRotate(trans, -M_PI_2);
                    
                    trans = CGAffineTransformTranslate(trans, -nodeModel.mediaWidth,((float)_videoSize.width/scale/2.0- nodeModel.mediaHeight/2.0));
                    
                    
                    [avMutableVideoCompositionLayerInstruction setTransform:trans
                                                                     atTime:CMTimeMakeWithSeconds(nodeModel.startTime, kVideoFrame)];
                }
                else
                {
                    scale = _videoSize.height/nodeModel.mediaHeight;
                    CGAffineTransform trans = CGAffineTransformMakeScale(scale, scale);
                    
                    trans = CGAffineTransformTranslate(trans,((float)_videoSize.width/scale/2.0- nodeModel.mediaWidth/2.0),0);
                    
                    
                    [avMutableVideoCompositionLayerInstruction setTransform:trans
                                                                     atTime:CMTimeMakeWithSeconds(nodeModel.startTime, kVideoFrame)];
                }
            }
            else
            {
                scale = _videoSize.width/nodeModel.mediaWidth;
                CGAffineTransform trans = CGAffineTransformMake(insertAssetTrack.preferredTransform.a*scale, insertAssetTrack.preferredTransform.b*scale, insertAssetTrack.preferredTransform.c*scale, insertAssetTrack.preferredTransform.d*scale, insertAssetTrack.preferredTransform.tx*scale, insertAssetTrack.preferredTransform.ty*scale);

                [avMutableVideoCompositionLayerInstruction setTransform:trans
                                                                 atTime:CMTimeMakeWithSeconds(nodeModel.startTime, kVideoFrame)];
            }
//
//            [avMutableVideoCompositionLayerInstruction setTransform:insertTransform
//                                                             atTime:CMTimeMakeWithSeconds(nodeModel.startTime, videoFrame)];
            
        }
        else
        {
            [videoMutableCompositionTrack insertTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(nodeModel.startTime, kVideoFrame),
                                                                       CMTimeMakeWithSeconds(nodeModel.duration, kVideoFrame))
                                                  ofTrack:oriVideoAssetTrack
                                                   atTime:CMTimeMakeWithSeconds(nodeModel.startTime, kVideoFrame)
                                                    error:&error];


            [avMutableVideoCompositionLayerInstruction setTransform:oriVideoAssetTrack.preferredTransform
                                                             atTime:CMTimeMakeWithSeconds(nodeModel.startTime, kVideoFrame)];
        }
    }
    [instructions addObject:avMutableVideoCompositionLayerInstruction];
    
    //插入音频
    if ( [audioMutableCompositionTrack insertTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0, kVideoFrame),
                                                                    CMTimeMakeWithSeconds(originAssetDuration, kVideoFrame))
                                            ofTrack:oriAudioAssetTrack
                                             atTime:kCMTimeZero
                                              error:&error])
    {
        //            auMutableCompositionTrack.preferredTransform = auAssetTrack.preferredTransform;
    }
    
    AVMutableVideoCompositionInstruction *avMutableVideoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    
    [avMutableVideoCompositionInstruction setTimeRange:CMTimeRangeMake(kCMTimeZero, [resultComposition duration])];
    

    avMutableVideoCompositionInstruction.layerInstructions = instructions;
    
    
    //插入视频处理
    AVMutableVideoComposition *avMutableVideoComposition = [AVMutableVideoComposition videoComposition];
    avMutableVideoComposition.renderSize = _videoSize;
    avMutableVideoComposition.frameDuration = CMTimeMake(1, 30);
    //avMutableVideoComposition.instructions = instructions;
    avMutableVideoComposition.instructions = [NSArray arrayWithObject:avMutableVideoCompositionInstruction];



    NSString *documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL* saveLocationURL = [[NSURL alloc] initFileURLWithPath:[NSString stringWithFormat:@"%@/mixResult.mp4", documents]];
    if ([fileManager fileExistsAtPath:saveLocationURL.relativePath])
    {
        [fileManager removeItemAtURL:saveLocationURL
                               error:nil];
    }
    
    AVAssetExportSession *avAssetExportSession = [[AVAssetExportSession alloc] initWithAsset:resultComposition
                                                                                  presetName:AVAssetExportPresetMediumQuality];
    [avAssetExportSession setVideoComposition:avMutableVideoComposition];
    [avAssetExportSession setOutputURL:saveLocationURL];
    [avAssetExportSession setOutputFileType:AVFileTypeMPEG4];
    [avAssetExportSession setShouldOptimizeForNetworkUse:YES];
    [avAssetExportSession exportAsynchronouslyWithCompletionHandler:^(void)
     {
         switch (avAssetExportSession.status)
         {
             case AVAssetExportSessionStatusExporting:
             {
                 NSLog(@"exporting progress %.2f",avAssetExportSession.progress);
                 if (self.progressBlock != nil)
                 {
                     self.progressBlock(avAssetExportSession.progress);
                 }
             }
                 break;
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
                 [fileManager removeItemAtURL:originVideoUrl
                                        error:nil];
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

- (void)initializeMusicFolderWithSuccessBlock:(void(^)(NSArray* array))successBlock
                                andErrorBlock:(void(^)(NSError *error))errorBlock
{
    NSArray *defaultMusicArray  = @[@"MKJ - Time",@"Matteo - Panama",@"Sam Tsui,Alex G - Don't Wanna Know／We Don't Talk Anymore",@"AnimeVibe - Умри если меня не любишь",@"Saphire - Be Good"];
    NSMutableArray *resultArray = [NSMutableArray array];
    for (int x = 0; x<defaultMusicArray.count; x++)
    {
        MusicFileModel *musicModel = [[MusicFileModel alloc] init];
        musicModel.fileName = defaultMusicArray[x];
        NSString *path =[ [NSBundle mainBundle]  pathForResource:musicModel.fileName
                                                          ofType:@"mp3"];
        AVURLAsset *avURLAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:path]
                                                         options:nil];
        musicModel.duration = avURLAsset.duration.value/avURLAsset.duration.timescale;
        for (NSString *format in [avURLAsset availableMetadataFormats])
        {
            for (AVMetadataItem *metaData in [avURLAsset metadataForFormat:format])
            {
                NSLog(@"%@",metaData.commonKey);
                if ([metaData.commonKey isEqualToString:@"title"])
                {
                    musicModel.musicName = (NSString*)metaData.value;
                }
                else if ([metaData.commonKey isEqualToString:@"artwork"])
                {
                    musicModel.coverImage = [UIImage imageWithData:(NSData*)metaData.value];
                }
                else if ([metaData.commonKey isEqualToString:@"artist"])
                {
                    musicModel.artist = (NSString*)metaData.value;
                }
            }
        }
        [resultArray addObject:musicModel];
    }
    if (resultArray.count > 0)
    {
        successBlock(resultArray);
    }
    else
    {
        errorBlock(nil);
    }
}

- (CAAnimationGroup*)createAnimationGroupForNode:(NSArray*)nodeArray
                                        WithSize:(CGSize)targetSize
{
    NSTimeInterval totalDuration = AVCoreAnimationBeginTimeAtZero;
    CAAnimationGroup *group = [CAAnimationGroup animation];
    NSMutableArray *animations = [NSMutableArray array];
    
    for (int index = 0; index<nodeArray.count; index++)
    {
        ZWPhotosNodeModel *nodeModel = nodeArray[index];
        if (nodeModel.type == ZWPhotosNodeTypePicture)
        {
            CAKeyframeAnimation * contentsAnimation;
            contentsAnimation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
            contentsAnimation.duration = 0.5f;
            contentsAnimation.removedOnCompletion = NO;
            contentsAnimation.fillMode = kCAFillModeForwards;
            UIImage *tempImage = nodeModel.object;
            contentsAnimation.values = @[(__bridge UIImage*)tempImage.CGImage];
            contentsAnimation.beginTime = nodeModel.startTime;
            [animations addObject:contentsAnimation];
            if (index != 0)
            {
                CAKeyframeAnimation * showAnimation;
                showAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
                showAnimation.duration = 0.5;
                //animation.delegate = self;
                showAnimation.removedOnCompletion = NO;
                showAnimation.fillMode = kCAFillModeForwards;
                showAnimation.values = @[[NSNumber numberWithFloat:0.0],
                                         [NSNumber numberWithFloat:1.0]];
                showAnimation.beginTime = nodeModel.startTime;
                [animations addObject:showAnimation];
            }
            
            CGFloat imageWidth  = 0;
            CGFloat imageHeight = 0;
            if (tempImage.size.width > tempImage.size.height)
            {
                imageWidth  = targetSize.width;
                imageHeight = imageWidth/tempImage.size.width*tempImage.size.height;
            }
            else
            {
                imageHeight = targetSize.height;
                imageWidth  = imageHeight/tempImage.size.height*tempImage.size.width;
            }
            CGFloat xPoint = targetSize.width/2.0 - imageWidth/2.0;
            CGFloat yPoint = targetSize.height/2.0 - imageHeight/2.0;
            
            CAKeyframeAnimation * boundsAnimation;
            boundsAnimation = [CAKeyframeAnimation animationWithKeyPath:@"bounds"];
            boundsAnimation.duration = 0.5f;
            //animation.delegate = self;
            boundsAnimation.removedOnCompletion = NO;
            boundsAnimation.fillMode = kCAFillModeForwards;
            boundsAnimation.values = @[[NSValue valueWithCGRect:CGRectMake(xPoint,yPoint,imageWidth,imageHeight)]];
            boundsAnimation.beginTime = nodeModel.startTime;
            [animations addObject:boundsAnimation];
            
            CAKeyframeAnimation *scaleZeroAnimation;
            scaleZeroAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
            scaleZeroAnimation.duration = 0.5f;
            scaleZeroAnimation.removedOnCompletion = NO;
            scaleZeroAnimation.autoreverses = YES;
            scaleZeroAnimation.fillMode = kCAFillModeForwards;
            scaleZeroAnimation.values = @[[NSNumber numberWithFloat:1]];
            scaleZeroAnimation.beginTime = nodeModel.startTime;
            [animations addObject:scaleZeroAnimation];
            
            CAKeyframeAnimation *scaleAnimation;
            scaleAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
            scaleAnimation.duration = 2.0f;
            scaleAnimation.removedOnCompletion = NO;
            scaleAnimation.fillMode = kCAFillModeForwards;
            scaleAnimation.values = @[[NSNumber numberWithFloat:1],
                                      [NSNumber numberWithFloat:2.0]];
            scaleAnimation.beginTime = nodeModel.startTime+0.5;
            [animations addObject:scaleAnimation];
            
            CAKeyframeAnimation * dissAnimation;
            dissAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
            dissAnimation.duration = 0.5;
            //animation.delegate = self;
            dissAnimation.removedOnCompletion = NO;
            dissAnimation.fillMode = kCAFillModeForwards;
            dissAnimation.values = (index == (int)nodeArray.count - 1)?@[[NSNumber numberWithFloat:1.0],
                                                                                [NSNumber numberWithFloat:0.8],
                                                                                [NSNumber numberWithFloat:0.4],
                                                                                [NSNumber numberWithFloat:0.0]]:@[[NSNumber numberWithFloat:1.0],
                                                                                                                  [NSNumber numberWithFloat:0.5],
                                                                                                                  [NSNumber numberWithFloat:0.3],
                                                                                                                  [NSNumber numberWithFloat:0.2]];
            dissAnimation.beginTime = nodeModel.endTime - 0.5;
            [animations addObject:dissAnimation];
            totalDuration += nodeModel.duration;
        }
        else if (nodeModel.type == ZWPhotosNodeTypeVideo)
        {
            CAKeyframeAnimation * contentsAnimation;
            contentsAnimation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
            contentsAnimation.duration = 0.5f;
            contentsAnimation.removedOnCompletion = NO;
            contentsAnimation.fillMode = kCAFillModeForwards;
            contentsAnimation.values = @[_emptyImage];
            contentsAnimation.beginTime = nodeModel.startTime;
            [animations addObject:contentsAnimation];
            if (index != 0)
            {
                CAKeyframeAnimation * showAnimation;
                showAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
                showAnimation.duration = 0.5;
                //animation.delegate = self;
                showAnimation.removedOnCompletion = NO;
                showAnimation.fillMode = kCAFillModeForwards;
                showAnimation.values = @[[NSNumber numberWithFloat:0.0],
                                         [NSNumber numberWithFloat:1.0]];
                showAnimation.beginTime = nodeModel.startTime;
                [animations addObject:showAnimation];
            }
            
            totalDuration += nodeModel.duration;
        }
    }
    
    
    group.animations = animations;
    group.duration = totalDuration;
    group.fillMode = kCAFillModeForwards;
    group.removedOnCompletion = NO;
    
    return group;
}


@end
